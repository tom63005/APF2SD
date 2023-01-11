/*

 I hereby release this code to : Public Domain.
 APF2SD adapter code / Tom.Williams 06SEPT2013.
 the card I am using is [Arduino Uno w/ ATmega328]
 Purpose of this code: To receive bytes from the APF video-game cartridge and act on commands.
   Command List:  "GETDIR", "FORMATSD", "READFILE", "WRITEFILE", "CHDIR", "GETCART"
      Added:  "BANKON", "BANKOFF", "KEYSON"
 
 DEDICATED READ LOOP FOR ATF-MP1000 SD Adapter Testing.
 
 */
 
#include <STDIO.H>
#include <STDLIB.H>
#include "C:\\Users\\TWilliams913\\Documents\\Arduino\\APF2SD_Atmel_write_loop\\Boxing.INC"

// constants.
// Pin numbers -- 3 pins input, 3 pins output.
// const int apf_0_in_Pin = 14;  // A0  - we are reading from this
// const int apf_1_in_Pin = 15;  // A1  - these are the labels on the [Arduino Mini w/ ATmega328]
// const int apf_2_in_Pin = 16;  // A2
// const int apf_3_in_Pin = 17;  // A3
// const int apf_0_out_Pin = 5;  // PWM-5
// const int apf_1_out_Pin = 6;  // PWM-6
// const int apf_2_out_Pin = 7;  // PWM-7
// const int apf_3_out_Pin = 8;  // PWM-8
const int apf_0_out_Pin = 14;  // A0  - we are reading from this
const int apf_1_out_Pin = 15;  // A1  - these are the labels on the [Arduino Mini w/ ATmega328]
const int apf_2_out_Pin = 17;  // A3  -- Production PCB error...
const int apf_3_out_Pin = 18;  // A4
//const int apf_2_out_Pin = 16;  // A2
//const int apf_3_out_Pin = 17;  // A3
const int apf_0_in_Pin = 5;  // PWM-5
const int apf_1_in_Pin = 6;  // PWM-6
const int apf_2_in_Pin = 7;  // PWM-7
const int apf_3_in_Pin = 8;  // PWM-8

unsigned char apfInState;   // 4-bit number for input pins
unsigned char apfOutState;  // 4-bit number to write to output pins.

const unsigned char ascEOT = 4;   // 0x04;
const unsigned char ascCR  = 13;  // 0x0D;
const unsigned char ascLF  = 10;  // 0x0A;
const unsigned char ascBELL = 7;  // 0x07;
const unsigned char ascXON  = 17; // 0x11;
const unsigned char ascXOFF = 19; // 0x13;

// variables that change (no need to set input pin states)
//  to actually change the pins, use: digitalWrite(ledPin, ledState);
//  to actually read the pins, use: buttonState = digitalRead(buttonPin);
//  remember to initialize: pinMode(ledPin, OUTPUT);  *AND*  pinMode(buttonPin, INPUT);
unsigned char gSending;  //  "sending flag"
char * gBuffer;          //  global Buffer pointer (points to internal ROM or RAM)
unsigned int gLength;    // Size of the buffer   0-to-65535 bytes.
unsigned int gIndex;     // Index into the buffer
const char * strMary = "MARY HAD A LITTLE LAMB AND BOY, WERE THE DOCTORS SUPRISED.";
unsigned char apfSending;
// -----
// *IMPORTANT* --> Please remember the 'C' program stack and your variables and the library variables
// . . . . . . -- -- cannot take more than 2K RAM on the ATmega328.
//  However, you have 32K of Flash-ROM and 1K of EEPROM....
// -----
//  Update on using G540 EEPROM Programmer for ATmega328:  Sat, Sept-21-2013.
//  1) use a known-good ATmega328, program with blinkey (less than 8k program).
//  2) bring up the G540 software, pick the ATmega168, exit the software.
//  3) restart the software, it should still have the ATmega168 selected. - This will send
//  -- configuration data to the programmer, mapping the pins on the ZIF to proper signals
//  4) put in the pre-programmed ATmega328, (a) read data, (b) read config, (c) read ID
//  5) put in the brain-dead ATmega328, use the default program sequence:
//  -- Erase-BlankChk-Program-Verify-Encrypt  (yes, leave the "encrypt" on.)
//  -- the "encrypt" is read from your known-good, so it will be writeable.
//  -- the Arduindo boot-loader uses the ID for version and "UNO", etc and the
//  -- "encrypt" bits to store checksums.
//  ------

void setup()
{
  // Open serial communications and wait for port to open:
  Serial.begin(9600);

  pinMode(apf_0_in_Pin, INPUT);
  pinMode(apf_1_in_Pin, INPUT);
  pinMode(apf_2_in_Pin, INPUT);
  pinMode(apf_3_in_Pin, INPUT);
  pinMode(apf_0_out_Pin, OUTPUT);   // should not need to be initialized.
  pinMode(apf_1_out_Pin, OUTPUT);   // should not need to be initialized.
  pinMode(apf_2_out_Pin, OUTPUT);   // should not need to be initialized.
  pinMode(apf_3_out_Pin, OUTPUT);   // should not need to be initialized.

  Serial.println("APF-MP1000----Continuous-Read-Loop...");
}

void loop()
{
  unsigned char mainLoop;
  unsigned char apfRxChar;
  unsigned char apfBitNum;
  char * strOut;
  int apfCharPos;
  unsigned char apfTxChar;
  unsigned char apfTxBit;
  char strNum[4];
  int myCount = 0;
  int tmout;
  int byteCount;
  unsigned char apfBitsToSend[8];
  unsigned char apfSendBitNum;
  // ---------------
  strOut = (char *)malloc( 256 );
  mainLoop = 1;
  // ---------------
  while ( mainLoop ){   // note that when we leave this loop, we re-initialize the variables.                                                   
    getApfInput();   // read input pins, set global var: apfInState
    // Serial.print( " Incomming state: " );
    // itoa( apfInState, strNum, 16 );
    // Serial.print( strNum );
    // Serial.print( "  - " );
    switch( apfInState ) {
      case 0x08:                  // apf is sending us data
           setApfOutput( 0x07 );  // "I see you have data for me"
           for ( apfCharPos=0; apfCharPos == 255; apfCharPos++ ) {
             strOut[ apfCharPos ] = 0x00;
           }
           apfCharPos = 0;
           break;
      case 0x0C:      // apf is starting to send us a byte
           apfBitNum = 0;         // we are starting at the LSB and working our way up.
           apfRxChar = 0x00;      // zero out the receiving byte.
           setApfOutput( 0x04 );  //  "I see you are starting a byte"
           break;
      case 0x0F:                  // apf has sent a "one" bit
           bitSet( apfRxChar, apfBitNum );
           // no "break" here, we want to execute the same steps as we would for a zero bit.
      case 0x0E:                  // apf has semt a "zero" bit.
           setApfOutput( 0x05 );  // "I am done reading the bit"
           apfBitNum++;
           break;
      case 0x0D:   // apf is done sending that bit.
           setApfOutput( 0x03 );  // "I am waiting for next bit"
           break;
      case 0x09:   // apf is done with that byte.
           strOut[ apfCharPos ] = apfRxChar;
           apfCharPos++;
           setApfOutput( 0x06 );   // acknowledge that.
           break;
      case 0x0A:   // apf is done sending data.
           strOut[ apfCharPos ] = 0x00;   // string terminator
           Serial.print( (char *)strOut );
           apfCharPos = 0;
           setApfOutput( 0x01 );
           break;           
      case 0x00:   // apf has gone "idle"
           setApfOutput( 0x00 );   // we go "idle"
           break;
    }  // end switch-case
    //*******************************
    // end Input Routines.
    // start Output Routines.
    //********************************
    if( apfInState == 0x00 && gSending == 0 ){
       strcpy( strOut, strMary );
       if( myCount > 18 ){ myCount = 0; }
       itoa( myCount++, strNum, 10 );
       strcat( strOut, strNum );
       sendString( (char *)strOut );
    }
    if ( gSending && (apfInState == 0x00) && !apfSending ){  // logical AND is &&, bitwise is &
       // if we are idle, we can staert sending.
       setApfOutput( 0x08 );    // "I have data to send."
       Serial.println( " >> I have data for you" );
       getApfInput();
       while( apfInState != 0x07 && !apfSending ){getApfInput();}  // wait for Ack.
       Serial.println( "   << I got ACK-data." );
       getApfInput();
       while( gIndex < gLength && !apfSending ) {
          apfTxChar = gBuffer[gIndex++];
          setApfOutput( 0x0C );   // "starting a new Byte."
    //      Serial.print( " >> I have byte for you.  :" );
    //      strNum[0] = apfTxChar;
    //      strNum[1] = 0x00;
    //      Serial.write( apfTxChar );
    //      Serial.print( " : " );
    //      Serial.print( strNum );
    //      Serial.println( " ... " );
          getApfInput();
          while( apfInState != 0x04 && !apfSending ){getApfInput();}  // wait for Ack.
    //      Serial.println( "    << I got ACK-byte." );
          getApfInput();
          apfBitsToSend[0] = apfTxChar & 0x01;
          apfBitsToSend[1] = apfTxChar & 0x02;
          apfBitsToSend[2] = apfTxChar & 0x04;
          apfBitsToSend[3] = apfTxChar & 0x08;
          apfBitsToSend[4] = apfTxChar & 0x10;
          apfBitsToSend[5] = apfTxChar & 0x20;
          apfBitsToSend[6] = apfTxChar & 0x40;
          apfBitsToSend[7] = apfTxChar & 0x80;
          for( apfSendBitNum = 0; apfSendBitNum < 8 && !apfSending; apfSendBitNum++ ){
//             apfTxBit = apfTxChar & 0x01;  // get lowest bit using bit-wise AND
//             apfTxChar <<= 1;  // shift right one bit.
             apfTxBit = apfBitsToSend[apfSendBitNum];
             if ( apfTxBit != 0 ){
                setApfOutput( 0x0F );  // sending bit=1
     //           Serial.println( " >> I have bit=1 for you." );
             } else {
                setApfOutput( 0x0E );  // sending bit=0
     //           Serial.println( " >> I have bit=0 for you." );
             }
             getApfInput();
             while( apfInState != 0x05 && !apfSending){ getApfInput(); }  // wait for Ack.
     //        Serial.println( "    << I got BIT-ack." );
             setApfOutput( 0x0D );  // done with bit-send.
     //        Serial.println( " >> I am done with bit-send." );
             getApfInput();
             while( apfInState != 0x03 && !apfSending ){ getApfInput(); }  // wait for Ack.
     //        Serial.println( "    << I got DONE-W-BIT-ack." );
          }  // end of for-next (for bits in a byte)
          setApfOutput( 0x09 ); // done with byte-send.
    //      Serial.println( " >> I am DONE with BYTE-send." );
          getApfInput();
          while( apfInState != 0x06 && !apfSending ){ getApfInput(); }  // wait for Ack.
    //      Serial.println( "    << I got BYTE-DONE-ACK." );
       } // end of while( gIndex < gLength )      
       gSending = 0;
       setApfOutput( 0x0A );
       Serial.println( " >> I am DONE-WITH-ALL-DATA." );
       tmout=0;
       getApfInput();
       while( (apfInState != 0x01) && !apfSending && (tmout++ < 1000)){ getApfInput(); }  // wait for Ack.
       if( tmout<1000 ){ Serial.println( "    << I got ALL-DATA-DONE-ACK." ); }
       setApfOutput( 0x00 );  // return to Idle state.
       Serial.println( " >> I am GOING IDLE." );
       tmout=0;
       getApfInput();
       while((apfInState != 0x00) && !apfSending && (tmout++ < 1000)){ getApfInput(); }  // wait for Ack.
       Serial.println( "    << THE APF-GAME IS IDLE." );
  //     Serial.println( " If you type something in the Atmel Serial-Monitor window and SEND, It should display on the APF screen." );
    }  // end of if (gSending...
    // Serial.print( " - Outgoing state: " );
    // itoa( apfOutState, strNum, 16 );
    // Serial.print( strNum );
    // Serial.print( "  - mem =" );
    // Serial.print( freeRam() );
    // Serial.print( " => " );
    // itoa( apfBitNum, strNum, 16 );
    // Serial.print( " bit# " );
    // Serial.print( strNum );
    // Serial.print( " => " );
    // itoa( apfCharPos, strNum, 10 );
    // Serial.print( " charPos=" );
    // Serial.print( strNum );
    // Serial.print( " => " );
    // itoa( apfRxChar, strNum, 16 );
    // Serial.println( strNum );
    // ---
 //   if ( apfInState == 0x00 ){
 //      myCount++;
 //      if ( myCount > 20 ){
       //       while(1){ }
 //          myCount = 0;
 //      }
   //    itoa( myCount, strNum, 10 );
//       Serial.print( myCount );
//       Serial.println( "" );
       if ( byteCount = Serial.available() ){
         Serial.readBytes( strOut, byteCount );
         strOut[byteCount+1] = 0xFF;
         strOut[byteCount+2] = 0x00;
         sendString( strOut );
         Serial.print( "Sending : " );
         Serial.println( strOut );
       }
 //   } else {
 //      myCount--;
 //      if ( myCount < 1 ){
       //       while(1){ }
 //          myCount = 20;
 //      }
  //     itoa( myCount, strNum, 10 );
//       Serial.print( myCount );
//       Serial.println( "" );
 //   }      
 //a   if ( ( myCount == 10 ) && ( apfInState == 0x02 ) ){   // 0x02=unused.
 //a      sendBoxingCart();    // if you do not use the routine, it will not be included...
 //a   }
    delay( 7 );  // wait 1 millisecond.  -- move inside "apf is done with that byte"
  }  // end while-loop
} // end function loop()

int freeRam () {
  // http://jeelabs.org/2011/05/22/atmega-memory-use/
  extern int __heap_start, *__brkval; 
  int v; 
  return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
}

void setApfOutput( unsigned char datIn ){
    unsigned char apfBit0State;
    unsigned char apfBit1State;
    unsigned char apfBit2State;
    unsigned char apfBit3State;
    apfBit0State = (unsigned char)bitRead( datIn, 0 );
    apfBit1State = (unsigned char)bitRead( datIn, 1 );
    apfBit2State = (unsigned char)bitRead( datIn, 2 );
    apfBit3State = (unsigned char)bitRead( datIn, 3 );
    digitalWrite( apf_0_out_Pin, apfBit0State );
    digitalWrite( apf_1_out_Pin, apfBit1State );
    digitalWrite( apf_2_out_Pin, apfBit2State );
    digitalWrite( apf_3_out_Pin, apfBit3State );
    apfOutState = datIn;
//    delay( 1 );    
}

void getApfInput( ){
    unsigned char apfBit0In;
    unsigned char apfBit1In;
    unsigned char apfBit2In;
    unsigned char apfBit3In;
    apfBit0In = digitalRead( apf_0_in_Pin );
    apfBit1In = digitalRead( apf_1_in_Pin );
    apfBit2In = digitalRead( apf_2_in_Pin );
    apfBit3In = digitalRead( apf_3_in_Pin );
    apfInState = 0x00;
    if( apfBit0In ) { bitSet( apfInState, 0 ); }
    if( apfBit1In ) { bitSet( apfInState, 1 ); }
    if( apfBit2In ) { bitSet( apfInState, 2 ); }
    if( apfBit3In ) { bitSet( apfInState, 3 ); }
    apfSending = apfBit3In;
//    delay( 1 );
}

void sendBoxingCart( ){
  gSending = 1;
  gBuffer = (char *)BoxingBytes;
  gLength = 4096;
  gIndex = 0;
}


void sendString( char * dataToSend ){
  gSending = 1;
  gBuffer = (char *)dataToSend;
  gLength = strlen( dataToSend );   // if it ends in Zero, this will work.
  gIndex = 0;
}
