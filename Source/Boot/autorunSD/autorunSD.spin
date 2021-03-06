{{

----------------------------------

Parallax BadgeWX SD Loader stage
  
Written by: Michael Mulholland
Last Update: 2019 Jan 27

----------------------------------

' ****************************************************
' FROM THIS SRC, GENERATE A FILE CALLED: autorunSD.bin
' UPLOAD TO BADGEWX WIFI MODULE  /file folder IN MFG
' ****************************************************


' ------------------------------------------------------------------------------------------------------------------------

' Version history

' ------------------------------------------------------------------------------------------------------------------------

' 2019.01.27.
'
'       Add delay after saving JOIN data to WiFi module- it seems to prevent the random crashing.
'               I think the real source of the issue is related closer to FRUN in P-ESP.
'               However- I'd rather resources are put into updating P-ESP to the fast binary PropLoader,
'               instead of messing with this timeout issue with the slow EEprom loader.
'
'

' 2019.01.21.
'
'       Forcibly switch off RGB LEDs at boot time
'       Add copy-from-SD-to-EEprom feature
'


' 2018.06.19.
'
'       Change serial code to include break feature
'

' 2018.06.15.
'
'       Added new Parallax-ESP command "SETAP,ssid,password". Use that instead of JOIN



' 2018.05.17.
'
'       More shrinking, including OBJ files
'       Remove testing LED flash at start
'       Rename and tidy for release
'       Extend to 32 char SSID and PASSWORD
'       Remove dependence on CR, LF, EOL chars
'


' 2018.04.16.
'
'       Initial version



' ------------------------------------------------------------------------------------------------------------------------

' TODO: Add rock solid error handling around the SD routines
' -- idea- stick WiFi autorun into another cog which runs at start, configs the wifi connection,
'          waits 30 seconds (or whatever is appropriate)
'          then runs the FRUN command (or 

' ------------------------------------------------------------------------------------------------------------------------
' ------------------------------------------------------------------------------------------------------------------------
' ------------------------------------------------------------------------------------------------------------------------ 



Steps...

1. Display Loading message

2. Blink LEDS (fairly quick, to suggest something happening fast!)

3. FRUN control the WiFi module to load/run autorunBL.bin (This will kill this code, BUT oled will keep the loading image!)

4. If autorunBL.bin not found, nothing left to do ! (Consider OLED msg?)

 
' ------------------------------------------------------------------------------------------------------------------------ 

}}


CON
        _clkmode = xtal1 + pll16x                       'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

        LED_COM = 9

        OLED_CS  = 18
        OLED_RST = 19
        OLED_CLK = 20
        OLED_DAT = 21
        OLED_DC  = 22

        WX_DI =  30 ' Duplicate pin defines, from WiFi module perspective, used in WiFi code
        WX_DO =  31 ' Duplicate pin defines, from WiFi module perspective, used in WiFi code

        WX_RES = 16 ' ESP WiFi module Reset Pin
        WX_BOOT = 17 ' ESP Bootloader Lock Pin

        STRIP_PIN = 10
        STRIP_LEN = 4
         
       
        ' SD pins (REV A2 - Black Badge)
        _dopin = 8
        _clkpin = 7
        _dipin = 6
        _cspin = 5
        _cdpin = -1 ' -1 if unused.
        _wppin = -1 ' -1 if unused.
        
        ' Eeprom stuff
        pagesize = 128 ' BadgeWX uses : M24512-RDW6TP 
         
         
VAR

        'long idx', WiFiCogReady', resetWiFi

        byte ssid[44], pass[44]

        byte buffer[256]
        
        'long timeoutMillis
                
        'long Stack[128]

        long pixels1[STRIP_LEN]

        'byte taskactive

OBJ
        
        wificom : "FullDuplexSerial_badgewx_minimal"
        oled    : "sj_oled_badgewx_minimal"
        sd      : "SD-MMC_FATEngine_badgewx_minimal"
        strip   : "jm_rgbx_pixel_minimal"
        i2c     : "pasm_i2c_driver_minimal"

PUB Start' | idx, r', joined ', errorStr

  ' Debug terminal delay
  'waitcnt(clkfreq + cnt)
   

  'resetWiFi := 0
  'WiFiCogReady := 0
  

  ' Call WiFi cog (which also operates as watchdog)
  'cognew(WiFiCog, @Stack)

  ' Clear joined flag
  'joined := 0



  
    
  ' Set wiFi module to command mode, by holding DI low longer than 30/baud seconds
  DIRA[WX_DI]~~               ' Set to output
  OUTA[WX_DI]~                ' Set to low
      
  waitcnt(clkfreq/800 + cnt)  ' pause
   
  DIRA[WX_DI]~                ' Set to input
      
   
  wificom.start(WX_DO,WX_DI,0,115200) ' rxpin, txpin, mode, baudrate
      
   
  ' TODO: How to handle situation when ESP really doesn't respond? Flash LED a certain way?
  ' hmm.. LED1 should be stuck on in this case, to indicate autorunSD has failed- which must be an ESP issue.
   
  'wificom.str(string($FE,"CHECK:module-name",13,10))


  ' Set up and clear RGB LEDs
  longfill(@pixels1, $00_00_05_00, STRIP_LEN) ' Blue 05 for nice calm Blue color (testing - change to off for Production)
  'longfill(@pixels1, $00_00_00_00, STRIP_LEN) ' All zero = All LED's off

  
  ' Recalculated timing based on minimum values published in WorldSemi datasheet, + 50
  ' Concept:
  ' 1. maximum should not be a concern for Propeller to time within,
  ' 2. and we just need to pass minimum a little bit for tolerance.
  
  strip.startx(@pixels1, STRIP_LEN, STRIP_PIN, 1_0, true, 24, 250,700,600,500) ' Timing for RevA 1818, RevB 1823

  ' Clear two outer pixels
  pixels1[0] := $00_00_00_00
  pixels1[3] := $00_00_00_00
  
  
  ' Set up display
  oled.init(OLED_CS, OLED_DC, OLED_DAT, OLED_CLK, OLED_RST)
     
  oled.write2x8String(string(" HELLO! "),8,0)   ' (str,len,row)  
  oled.write4x16String(string(" Checking SD... "),16,6,0)
  
  oled.updateDisplay
  
    
  'repeat until WiFiCogReady == 1
    'waitcnt(0)



  ' -------------------------------
  ' SD card related stuff
  ' -------------------------------

  
  'timeoutMillis := 2000  ' Reset watchdog
  

  sd.fatEngineStart( _dopin, _clkpin, _dipin, _cspin, -1, -1, -1, -1, -1)

  \sd.mountPartition(0)

  
  if sd.partitionMounted


        'oled.write4x16String(string(" SD Card Ready  "),16,7,0)
        'oled.updateDisplay
        
                  

        ' Check SD card for lock.txt, and write lock settings to ESP module if exist 
        \sd_wifiLockState
        
            
        ' Check SD card for wifi.txt, and write wifi settings to ESP module if exist 
        \sd_wifiSettings
         
        
        ' Check SD card for save.eeprom file, and save to eeprom if exists
        'errorStr:=
        \sd_saveEEprom
         
        'pixels1[0] := $05_00_00_00 
         
        oled.write4x16String(string("  Reading SD... "),16,6,0)
        oled.updateDisplay
         
         
        ' Check SD card for autorun.rom (eeprom format), and boot if exists
        '\sd_autorunEEprom
        \sd.bootPartition(string("autorun.rom")) 
         
        'pixels1[1] := $05_00_00_00
        ' Won't reach here if autorun was successful
         
         
        ' Check SD card for autorun.bin (binary format), and boot if exists
        '\sd_autorunBinary
        \sd.bootPartition(string("autorun.bin")) 
         
        'pixels1[2] := $05_00_00_00
        ' Won't reach here if autorun was successful
         

                 
        if(sd.partitionMounted)
          \sd.unmountPartition 

        

  'else

  

        'oled.write4x16String(string(" no SD Card...  "),16,7,0)
        'oled.updateDisplay
        'pixels1[3] := $05_00_05_00
        



  ' Update oled message for next stage
  oled.write4x16String(string("Searching WiFi.."),16,6,0)
  oled.updateDisplay
        
        
  longfill(@pixels1, $00_00_00_00, STRIP_LEN) ' All zero = All LED's off

  ' Note: Consider the time needed for the RGB's to update- ensure enough time before FRUN executed below!
  


  ' --- FRUN load the next autorun stage

  'wificom.str(string($FE,"CHECK:module-name",13,10))
  'wificom.str(string($FE,"CHECK:wifi-mode",13,10))

  {r:=0
  repeat 16

    idx := wificom.rxcheck

    'write5x7Char(ch,row,col)
    oled.write5x7Char(idx,5,r++)
    oled.updateDisplay


  repeat 10
    waitcnt(clkfreq + cnt)
   } 

  'wificom.rxflush
  
  ''wificom.str(string($FE,"FRUN:autorunBL.bin",13,10))



  wificom.str(string($FE,"CHECK:module-name",13,10))
  waitcnt(clkfreq / 1000 + cnt)
  wificom.str(string($FE,"CHECK:wifi-mode",13,10))
  waitcnt(clkfreq / 1000 + cnt)
  
  wificom.str(string($FE,"FRUN:autorunBL.bin",13,10))
  
  'wificom.stop
  

  ' DO NOT RX or TX to WIFICOM after issuing FRUN command !



  ' Sometimes the FRUN autorunBL.bin executes, but fails to run.
  ' Usually after JOIN command sent.
  

  
    

  'wificom.str(string($FE,"FRUN:autorunBL.bin",13,10))

  'wificom.str(string($FE,"FRUN:autorunBL.bin",13,10))

  ' TODO: Check reply, and try X times....
  

  {
  ' Clear timeout so next stage Bootloader loads immediately
  ' Is this signed? ... set to 1 rather than zero for now. Only 1ms delay
  timeoutMillis := 1


  ' 3 second wait, allow FRUN to execute in other cog
  repeat 3
    waitcnt(clkfreq + cnt)
  

  ' ---
  }  

  
  ' Should never reach here, if WiFi module executed the FRUN

  waitcnt(clkfreq + cnt)
  
  ' --- BLINK LED 2 as diagnostic info for tech support (will blink if FRUN failed; most likely ESP connection issue)

  repeat 
   
      OUTA[LED_COM]~~           ' Set to high
      DIRA[LED_COM]~~           ' Set to output
      
      waitcnt(clkfreq/8 + cnt)  ' 1/8 second pause
   
      DIRA[LED_COM]~            ' Set to input

   


' ----------------------------------------------------------------------------------------------------------------
  

{
PRI WiFiCog


    ' Set wiFi module to command mode, by holding DI low longer than 30/baud seconds
    DIRA[WX_DI]~~               ' Set to output
    OUTA[WX_DI]~                ' Set to low
        
    waitcnt(clkfreq/800 + cnt)  ' pause

    DIRA[WX_DI]~                ' Set to input
        
     
    wificom.start(WX_DO,WX_DI,0,115200) ' rxpin, txpin, mode, baudrate
        

    ' TODO: How to handle situation when ESP really doesn't respond? Flash LED a certain way?
    ' hmm.. LED1 should be stuck on in this case, to indicate autorunSD has failed- which must be an ESP issue.

    wificom.str(string($FE,"CHECK:module-name",13,10))
                
    'WiFiCogReady := 1      
  
          
    ' Wait for timeout seconds...
    ' - Cog0 will keep updating this timer whilst it is operating correctly,
    '   so the timer will expire if something goes wrong!
    timeoutMillis := 2000

    
    repeat until timeoutMillis < 1

        waitcnt(clkfreq/1000 + cnt)
        --timeoutMillis
        

        
    ' Update oled message for next stage
    oled.write4x16String(string("Searching WiFi.."),16,6,0)
    oled.updateDisplay

    
    ' Talk to ESP- make sure it's alive after the reset
    ' else this data may be useful for future application
    
    wificom.rxflush ' Clear the buffer (it will be full of junk since the reboot - the pause might be what's needed, rather than the actual flush :)

    wificom.str(string($FE,"CHECK:wifi-mode",13,10))


    'OUTA[LED_COM]~~           ' Set to high , LED 1
    'DIRA[LED_COM]~~           ' Set to output
            

    waitcnt(clkfreq + cnt) ' This delay before FRUN, along with "check wifi mode" removes the need for rebooting the esp after first setting credentials.


    longfill(@pixels1, $00_00_00_00, STRIP_LEN) ' All zero = All LED's off


    ' disable bootloader lock- IMPORTANT!
    OUTA[WX_BOOT]~~          ' Set to high
    DIRA[WX_BOOT]~~          ' Set to output

          

    {if (taskactive==0)
      OUTA[LED_COM]~~           ' Set to high , LED 1
      DIRA[LED_COM]~~           ' Set to output

      'pixels1[0] := $05_00_00_00

    repeat until taskactive==1
      waitcnt(0) }

    'pixels1[1] := $05_00_00_00
    
    ' --- FRUN load the next autorun stage
    wificom.str(string($FE,"FRUN:autorunBL.bin",13,10))

    
    'waitcnt(clkfreq + cnt)

    

    'OUTA[LED_COM]~            ' Set to low , LED 0
    'DIRA[LED_COM]~~           ' Set to output
      
    'wificom.str(string($FE,"FRUN:autorunBL.bin",13,10))

    'pixels1[3] := $05_00_00_00
    
    ' Allow about 1.9mS + fudge factor, to transmit the msg before stopping the cogs
    
    ' HALT!
    
    repeat
      waitcnt(0)  
    

' ----------------------------------------------------------------------------------------------------------------
}


' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------


{
PRI sd_init


    ' Reset timeout
    timeoutMillis := 2000
    

    if !sd.fatEngineStart( _dopin, _clkpin, _dipin, _cspin, -1, -1, -1, -1, -1)
        return 'false
        
     
    if(sd.partitionMounted)
        \sd.unmountPartition ' trap and ignore errors with \
     
     
    sd.mountPartition(0)
     
     
    if(!sd.partitionMounted)
        return 'false
         
     
    ' Reset timeout
    timeoutMillis := 2000
    

    return true
    
}
' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------


PRI sd_wifiLockState | bufidx, charcount, idx

  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  
  ' // Check for WiFi lockstate file

  ' /////////////////////////////////////////////////////////////////////////////////////////////
  

  
  ' /////
  
  ' LOGIC
  '
  ' valid char in the range 0 to 2
  '
  ' 0. remove
  
  ' 1. neutral, default

  ' 2. force lock
  
  ' /////
  
    
     
    ' Reset timeout
    'timeoutMillis := 2000
    
     
    sd.openFile(string("lock.txt"), "R")

    charcount := sd.readData(@buffer, 128)
    
    ' Got data?
    if (charcount > 0)
      

        ' parse buffer
        bufidx := 0

  
        ' ignore any control chars at start of file (CR, LF, etc...)    
        repeat while ( ((buffer[bufidx] < 32) or (buffer[bufidx] > 126)) and (bufidx < charcount) )
            bufidx++

  

        ' grab LOCK STATE value, up until next control char, or EOF
        idx := 0
        repeat while ( (buffer[bufidx] > 31) and (buffer[bufidx] < 127) and (bufidx < charcount) )
            ssid[idx++] := buffer[bufidx++]

         


        ' disable bootloader lock- IMPORTANT!
        OUTA[WX_BOOT]~~          ' Set to high
        DIRA[WX_BOOT]~~          ' Set to output
  
  
  
        ' Send JOIN network command to WiFi module
         
        wificom.rxflush   ' Clear RX buffer

        wificom.str(string($FE,"CHECK:module-name",13,10))
        waitcnt(clkfreq / 1000 + cnt) 
        wificom.str(string($FE,"LOCK:"))
        wificom.str(@ssid)
        wificom.str(string(13,10))
                
         
                


' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------



PRI sd_wifiSettings | bufidx, charcount, idx

  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  
  ' // Check for WiFi settings file

  ' /////////////////////////////////////////////////////////////////////////////////////////////
  

  
  ' /////
  
  ' LOGIC
  '
  ' valid char in the range 32 to 126
  '
  ' 1. read chars until first valid char (abort if EOF)
  
  ' 2. SSID = read chars until first non-valid char; could be CR, LF, whatever (abort if EOF, or more than 32 chars)

  ' 3. read chars until next valid char (abort if EOF)

  ' 4. PASS = read chars until first non-valid char; could be CR, LF, whatever (abort if EOF, or more than 32 chars)

  ' /////
  
    
     
    ' Reset timeout
    'timeoutMillis := 4000
    
     
    sd.openFile(string("wifi.txt"), "R")

    charcount := sd.readData(@buffer, 128)
    
    ' Got data?
    if (charcount > 1)
      

        oled.write4x16String(string("Save WiFi Data  "),16,6,0)
        oled.updateDisplay 
      

        ' parse buffer
        bufidx := 0

  
        ' ignore any control chars at start of file (CR, LF, etc...)    
        repeat while ( ((buffer[bufidx] < 32) or (buffer[bufidx] > 126)) and (bufidx < charcount) )
            bufidx++

  

        ' grab SSID up until next control char, or EOF
        idx := 0
        repeat while ( (buffer[bufidx] > 31) and (buffer[bufidx] < 127) and (bufidx < charcount) )
            ssid[idx++] := buffer[bufidx++]


  
        ' ignore any control chars at start of file (CR, LF, etc...)    
        repeat while ( ((buffer[bufidx] < 32) or (buffer[bufidx] > 126)) and (bufidx < charcount) )
            bufidx++


         
        ' grab PASS up until next control char, or EOF
        idx := 0
        repeat while ( (buffer[bufidx] > 31) and (buffer[bufidx] < 127) and (bufidx < charcount) )
            pass[idx++] := buffer[bufidx++]



        ' disable bootloader lock- IMPORTANT!
        OUTA[WX_BOOT]~~          ' Set to high
        DIRA[WX_BOOT]~~          ' Set to output
  
  
  
        ' Send JOIN network command to WiFi module
         
        'wificom.rxflush   ' Clear RX buffer

        wificom.str(string($FE,"CHECK:wifi-mode",13,10))
        waitcnt(clkfreq / 1000 + cnt)

        ' Moved this code to the first autorun.bin (to fix the issue of occassional lockups)
        {wificom.str(string($FE,"SET:wifi-mode,STA+AP",13,10))
        waitcnt(clkfreq/4 + cnt)
         
        wificom.str(string($FE,"SET:wifi-mode,STA",13,10))
        waitcnt(clkfreq/4 + cnt)}
        
        wificom.str(string($FE,"JOIN:")) 
        wificom.str(@ssid)
        wificom.str(string(","))
        'wificom.str(string("BADDPASS")) ' TEST
        wificom.str(@pass)
        wificom.str(string(13,10))



        ' Must wait 5 seconds after JOIN command, else FRUN will often fail!

        idx := 53
        
        repeat until idx == 47
        
          oled.write5x7Char(idx--,6,15) ' (ch,row,col) 
          oled.updateDisplay

          waitcnt((clkfreq) + cnt)

        
' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------


PRI sd_saveEEprom | charcount, pages, i, d, eepromAddress


  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  
  ' // Check for eeprom-save file
  '
  ' // Must be EEprom file format, with filename: save.rom

  ' /////////////////////////////////////////////////////////////////////////////////////////////
  
  'timeoutMillis := 4000

  sd.openFile(string("save.rom"), "R")

  oled.write4x16String(string("Saving to EEprom"),16,6,0)
  oled.updateDisplay
   
  charcount:= sd.fileSize

  ' Minimum binary file: 28 bytes (Variable size)
  ' Minimum eeprom file: 32768 bytes (Fixed size)
   
  ' TODO: Future version could handle binary files if header/footer reference found.
   
  if charcount == 32768
   
      i2c.Initialize(i2c#BootPin)
      i2c.Start(i2c#BootPin)
      
      eepromAddress := 0
      
      pages := charcount / pagesize
                  
      i := 0
      d := charcount / 16 ' maximum 16 chars on OLED
      
      repeat pages

          if eepromAddress // d == 0 ' Update progress bar on oled
             
             oled.write5x7Char(43,7,i) '(ch,row,col)
             oled.updateDisplay
             i++
             
          sd.readData(@buffer, pagesize)

          i2c.writePage(i2c#BootPin, i2c#EEPROM, eepromAddress, @buffer, pagesize)  
          repeat while i2c.WriteWait(i2c#BootPin, i2c#EEPROM, eepromAddress) ' Global timeout exists in another cog
             
          eepromAddress += pagesize
                              
          'timeoutMillis := 2000

          
      i2c.Stop(i2c#BootPin)

            

  ' Done
  oled.write4x16String(string("                "),16,7,0) ' Clear progress bar

  'return true

' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------

{
PRI sd_autorunBinary

     
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  
  ' // Check for autorun file
  '
  ' // Binary file format, with filename: autoload.bin
  '
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  
    
    timeoutMillis := 1000
     
     
    ' // Boot from autorun.bin, if the file exists
    sd.bootPartition(string("autorun.bin"))
   
   
    ' Won't get here if the boot worked!
    ' No need for clean up code, as Propeller will be rebooting next, and the SD files were read only.
    
    'sd.unmountPartition
          
    ' Reset timeout
    'timeoutMillis := 1000
          
    ' Stop SD Driver
    'waitcnt(clkfreq + cnt)
    'sd.fatEngineStop ' Give the block driver a second to finish up.

' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------
}
{
PRI sd_autorunEEprom

     
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  
  ' // Check for autorun file
  '
  ' // EEprom file format, with filename: autoload.rom
  '
  ' /////////////////////////////////////////////////////////////////////////////////////////////
  
    
    timeoutMillis := 1000
     
     
    ' // Boot from autorun.rom, if the file exists
    sd.bootPartition(string("autorun.rom"))
   
   
    ' Won't get here if the boot worked!
    ' No need for clean up code, as Propeller will be rebooting next, and the SD files were read only.
    
    'sd.unmountPartition
          
    ' Reset timeout
    'timeoutMillis := 1000
     
     
    ' Stop SD Driver
    'waitcnt(clkfreq + cnt)
    'sd.fatEngineStop ' Give the block driver a second to finish up.         
}
' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------