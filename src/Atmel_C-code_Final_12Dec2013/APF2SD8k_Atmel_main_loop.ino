/*
 I hereby release this code to : Public Domain.
 APF2SD adapter code / Tom.Williams 06SEPT2013.25OCT2013.
 the card I am using is [Arduino Uno w/ ATmega328]
 Purpose of this code: To receive bytes from the APF video-game cartridge and act on commands.
 Command List:  "GETDIR", "FORMATSD", "READFILE", "WRITEFILE", "CHDIR", "GETCART"
 Added:  "BANKON", "BANKOFF", "SERIALPASSTHRU"
 Removed unused commands and serial-debug: 12DEC2013.
 DEDICATED LOOP FOR ATF-MP1000 SD Adapter.
 */

#include <STDIO.H>
#include <STDLIB.H>
// #include "C:\\Users\\TWilliams913\\Documents\\Arduino\\APF2SD_Atmel_write_loop\\Boxing.INC"
#include <SD.h>

// constants.
// Pin numbers -- 3 pins input, 3 pins output.
const int apf_0_out_Pin = 14;  // A0  - APF 4066 is reading from this
const int apf_1_out_Pin = 15;  // A1  - these are the labels on the [Arduino Mini w/ ATmega328]
const int apf_2_out_Pin = 17;  // A3  -- Production PCB error...
const int apf_3_out_Pin = 18;  // A4  -- Production PCB error...
const int apf_0_in_Pin = 5;  // PWM-5  - From the APF 74LS197
const int apf_1_in_Pin = 6;  // PWM-6
const int apf_2_in_Pin = 7;  // PWM-7
const int apf_3_in_Pin = 8;  // PWM-8

//   -- Bank-Switch (Production PCB)..
const int apf_bnk_Pin = 9; // PWM-9  -- pin 15 of ATMega328. = pin 9 of 20v8.PLD

// const char * strMary = "ERROR: MARY HAD A LITTLE LAMB";  // "WITH RED WINE AND CRANBERRY SAUCE.";

char apfInState;   // 4-bit number for input pins
char apfOutState;  // 4-bit number to write to output pins.

// variables that change (no need to set input pin states)
//  to actually change the pins, use: digitalWrite(ledPin, ledState);
//  to actually read the pins, use: buttonState = digitalRead(buttonPin);
//  remember to initialize: pinMode(ledPin, OUTPUT);  *AND*  pinMode(buttonPin, INPUT);
char gSending;  //  "sending flag"
char * gBuffer; //  "what to send" global Buffer pointer (points to internal ROM or RAM)
int gLength;    // Size of the buffer   0-to-65535 bytes.
int gIndex;     // Index into the buffer   if not unsigned, (-32768)-to-(+32767)

char apfSending;
File gBinFile;   // moved to global vvariable due to "get next char from file" in apfDataSend.
char gError[40];
// -----
// *IMPORTANT* --> Please remember the 'C' program stack and your variables
//    and the library variables cannot take more than 2K RAM on the ATmega328.
//  However, you have 32K of Flash-ROM and 1K of EEPROM....
// -----

void setup()
{
  pinMode(apf_0_in_Pin, INPUT);
  pinMode(apf_1_in_Pin, INPUT);
  pinMode(apf_2_in_Pin, INPUT);
  pinMode(apf_3_in_Pin, INPUT);
  pinMode(apf_0_out_Pin, OUTPUT);   // should not need to be initialized. (output by default)
  pinMode(apf_1_out_Pin, OUTPUT);   // should not need to be initialized.
  pinMode(apf_2_out_Pin, OUTPUT);   // should not need to be initialized.
  pinMode(apf_3_out_Pin, OUTPUT);   // should not need to be initialized.

  pinMode(apf_bnk_Pin, OUTPUT);
  digitalWrite( apf_bnk_Pin, 1 );

  setApfOutput( 0x00 );   // "Arduino 4-bit handshake" = IDLE.

  pinMode(10, OUTPUT);
  digitalWrite( 10, HIGH );
  SD.begin(10);
}

void loop()
{
  char apfRxChar;
  char apfBitNum;
  char * strIn;    // input buffer
  int apfCharPos;
  int i;
  // ---------------
  getApfInput();
  while ( apfInState != 0 ){   // wait for APF to go IDLE.
    getApfInput();
  }
  // ---------------
  strIn = (char *)malloc( 60 );
  for( i=0; i<60; i++ ){
    strIn[i] = 0;
  }
  // ---------------
  gLength = 0;
  gIndex = 0;
  gError[0] = 0x00;
  gSending = 0;
  apfSending = 0;
  apfCharPos = 0;
  // ---------------
  while ( 1 ){
    getApfInput();   // read input pins, set global var: apfInState
    switch( apfInState ) {
    case 0x08:                  // apf is sending us data
      setApfOutput( 0x07 );  // "I see you have data for me"
      for( i=0; i<60; i++ ){
        strIn[i] = 0x00;
      }
      gError[0] = 0x00;
      gLength = 0;
      gSending = 0;
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
      strIn[ apfCharPos ] = apfRxChar;
      apfCharPos++;
      setApfOutput( 0x06 );   // acknowledge that.
      break;
    case 0x0A:   // apf is done sending data.
      strIn[ apfCharPos ] = 0x00;   // string terminator
      apfCharPos = 0;
      setApfOutput( 0x01 );
      apfSending = 0;
      break;
    case 0x00:   // apf has gone "idle"
      setApfOutput( 0x00 );   // we go "idle"
      interpretString( (char *)strIn );
      for( i=0; i<60; i++ ){
        strIn[i] = 0x00;
      }
      break;
    case 0x0B:
      digitalWrite( apf_bnk_Pin, 0 );
      setApfOutput( 0x02 );
      break;
    }  // end switch-case
    //*******************************
    // end Input Routines.
    // start Output Routines.
    //********************************
    if ( gSending && (apfInState == 0x00) && !apfSending ){  // logical AND is &&, bitwise is &
      // if we are idle, we can start sending.
      apfFileSend(  );
      gSending = 0;
      gError[0] = 0x00;
      gLength = 0;
      gIndex = 0;
      apfCharPos = 0;
    }  // end of if (gSending...
    delay( 3 );  // - milliseconds.
  }  // end while-loop
  free( strIn );   // if we leave the loop, we re-initialize the variables.
} // end function loop()

// int freeRam () {
//   // http://jeelabs.org/2011/05/22/atmega-memory-use/
//   extern int __heap_start, *__brkval;
//   int v;
//   return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval);
// }

void setApfOutput( unsigned char datIn ){
  char apfBit0State;
  char apfBit1State;
  char apfBit2State;
  char apfBit3State;
  apfBit0State = (char)bitRead( datIn, 0 );
  apfBit1State = (char)bitRead( datIn, 1 );
  apfBit2State = (char)bitRead( datIn, 2 );
  apfBit3State = (char)bitRead( datIn, 3 );
  digitalWrite( apf_0_out_Pin, apfBit0State );
  digitalWrite( apf_1_out_Pin, apfBit1State );
  digitalWrite( apf_2_out_Pin, apfBit2State );
  digitalWrite( apf_3_out_Pin, apfBit3State );
  apfOutState = datIn;
  //  delay( 2 );
}

void getApfInput( ){
  char apfBit0In;
  char apfBit1In;
  char apfBit2In;
  char apfBit3In;
  apfBit0In = (char)digitalRead( apf_0_in_Pin );
  apfBit1In = (char)digitalRead( apf_1_in_Pin );
  apfBit2In = (char)digitalRead( apf_2_in_Pin );
  apfBit3In = (char)digitalRead( apf_3_in_Pin );
  apfInState = 0x00;
  if( apfBit0In ) {
    bitSet( apfInState, 0 );
  }
  if( apfBit1In ) {
    bitSet( apfInState, 1 );
  }
  if( apfBit2In ) {
    bitSet( apfInState, 2 );
  }
  if( apfBit3In ) {
    bitSet( apfInState, 3 );
  }
  apfSending = apfBit3In;
  //  delay( 2 );
}

void mySendString( char * dataToSend ){
  gSending = 1;
  gBuffer = (char *)dataToSend;
  gLength = strlen( dataToSend );   // if it ends in Zero, this will work.
  gIndex = 0;
}

void interpretString( char * strCMD ){
  //   Command List:  "GETDIR", "FORMATSD", "READFILE", "WRITEFILE", "CHDIR", "GETCART"
  //    Added:  "BANKON", "BANKOFF", "SERIALPASSTHRU"
  // ----------
  if ( strlen( strCMD ) == 0 ){
    return;
  }
  if ( strcasecmp( strCMD, "GETDIR" ) == 0 ){
    reInitSD();
    //  root = SD.open("/");
    //  entry = root.openNextFile();
    //  strcpy( dirBuffer, entry.name() );     // 60-chars MAX (including end-of-string)
    mySendString( "== DIR-ENTRY SHOULD APPEAR HERE ==" );
    //  mySendString( dirBuffer );
    //  entry.close();
  }  /* end GETDIR */
  // -----
  if ( strcasecmp( strCMD, "GETGAME" ) == 0 ){
    reInitSD();
    gBinFile = SD.open("apfgame.BIN",FILE_READ);
    delay( 100 );
    gBinFile.seek( 0 );
    delay( 100 );
    if ( !gBinFile ){
      mySendString( "ERROR FILE NOT FOUND: APFGAME.BIN" );
    }
    apfFileSend( );
    gBinFile.close();
  } /* end GETGAME */
  // -----
  if ( strcasecmp( strCMD, "GETSPCD" ) == 0 ){  // Space Destroyers
    reInitSD();
    gBinFile = SD.open("spacdest.BIN",FILE_READ);
    delay( 100 );
    gBinFile.seek( 0 );
    delay( 100 );
    if ( !gBinFile ){
      mySendString( "ERROR FILE NOT FOUND: SPACDEST.BIN" );
    }
    apfFileSend( );
    gBinFile.close();
  } /* end GETSPCD */
  // -----
  if ( strcasecmp( strCMD, "GETFLASH" ) == 0 ){   //  Use for Flashing-EEPROM ** IN-PLACE.
    reInitSD();
    gBinFile = SD.open("apfflash.BIN",FILE_READ);
    delay( 100 );
    gBinFile.seek( 0 );
    delay( 100 );
    if ( !gBinFile ){
      mySendString( "ERROR FILE NOT FOUND: APFFLASH.BIN" );
    }
    apfFileSend( );
    gBinFile.close();
  } /* end GETFLASH */

  // BINDUMP
  if ( strncasecmp( strCMD, "BINDUMP", 7 ) == 0 ){
    reInitSD();
    gBinFile = SD.open( (char *)strCMD+8 ,FILE_READ );
    delay( 100 );
    gBinFile.seek( 0 );
    delay( 100 );
    if ( !gBinFile ){
      //      mySendString( "ERROR FILE NOT FOUND." );
      strcpy( gError, "ERROR FILE NOT FOUND: " );
      strcat( gError, strCMD+8 );
      mySendString( gError );
    }
    apfFileSend( );
    gBinFile.close();
  } // end BINDUMP
}

void reInitSD(){
  digitalWrite( 10, LOW );
  delay( 300 );
  digitalWrite( 10, HIGH );
  delay( 100 );
  SD.begin(10);
  delay( 300 );
}

void apfFileSend( ){
  char apfBitsToSend[8];
  char apfTxChar;
  char apfSendBitNum;
  int tmout;
  // ----------
  tmout = 0;
  getApfInput();
  while( apfInState != 0x00 && !apfSending ){
    getApfInput();
  }  // wait for Idle.
  setApfOutput( 0x08 );    // "I have data to send."
  getApfInput();
  while( apfInState != 0x07 && !apfSending ){
    getApfInput();
  }  // wait for Ack.
  getApfInput();
  gIndex = 0;
  if( gBinFile ){
    gLength = gBinFile.available();  // how many bytes are available to read from file?
  }
  else {
    gLength = strlen( gBuffer );
  }
  if ( gLength <= 0 ){
    return;
  }
  while( gIndex < gLength && !apfSending ) {
    if( gBinFile ){
      gBinFile.readBytes( (char *)&apfTxChar, 1 );    // read one-byte.
    }
    else {
      apfTxChar = gBuffer[ gIndex ];
    }
    setApfOutput( 0x0C );   // "starting a new Byte."
    getApfInput();
    while( apfInState != 0x04 && !apfSending ){
      getApfInput();
    }  // wait for Ack.
    getApfInput();
    apfBitsToSend[0] = apfTxChar & 0x01;
    apfBitsToSend[1] = apfTxChar & 0x02;
    apfBitsToSend[2] = apfTxChar & 0x04;
    apfBitsToSend[3] = apfTxChar & 0x08;
    apfBitsToSend[4] = apfTxChar & 0x10;
    apfBitsToSend[5] = apfTxChar & 0x20;
    apfBitsToSend[6] = apfTxChar & 0x40;
    apfBitsToSend[7] = apfTxChar & 0x80;
    for( apfSendBitNum = 7; apfSendBitNum >= 0; apfSendBitNum-- ){
      if ( apfBitsToSend[apfSendBitNum] != 0 ){
        setApfOutput( 0x0F );  // sending bit=1
      }
      else {
        setApfOutput( 0x0E );  // sending bit=0
      }
      getApfInput();
      while( apfInState != 0x05 && !apfSending){
        getApfInput();
      }  // wait for Ack.
      setApfOutput( 0x0D );  // done with bit-send.
      getApfInput();
      tmout=500;
      while( (apfInState != 0x03) && !apfSending && (tmout++ < 300)){
        getApfInput();
      }  // wait for Ack.
      getApfInput();
      if ( apfInState == 0x06 ){
        break;
      }
    }  // end of for-next (for bits in a byte)
    setApfOutput( 0x09 ); // done with byte-send.
    gIndex++;
    getApfInput();
    while( apfInState != 0x06 && !apfSending ){
      getApfInput();
    }  // wait for Ack.
  } // end of while( gIndex < gLength )
  gSending = 0;
  setApfOutput( 0x0A );
  tmout=2000;
  getApfInput();
  while( (apfInState != 0x01) && !apfSending && (tmout++ < 1000)){
    getApfInput();
  }  // wait for Ack.
  setApfOutput( 0x00 );  // return to Idle state.
  tmout=2000;
  getApfInput();
  while((apfInState != 0x00) && !apfSending && (tmout++ < 1000)){
    getApfInput();
  }  // wait for Ack.
}


