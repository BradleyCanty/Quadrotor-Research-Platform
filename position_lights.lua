--[[
position_lights.lua

Description:
    This script enables turning aircraft-mounted position LEDs on and off using a switch on the RC transmitter.
    The position lights are CREE XT-E high power constant-current LEDs. The lights do a double flash every 1.5 seconds,
    which is equivalent to 40 double-flashes per minute (1/1.5 [flashes/sec] * 60/1 [sec/min] = 40 [flashes/min])

Steps:
 1) Enable scripting: 
    Mission Planner -> Config tab -> Full Parameter List -> set SCR_ENABLE as 1

 2) Configure transmitter switch for turning the lights on/off: 
    This is transmitter-specific, but in general you must assign the letter of the desired TX switch to a channel number via the TX's interface.
    Set this script's 'INPUT_CHANNEL' variable, found below, to the choosen channel number.

 3) Choose a GPIO pin for sending the on/off signal to the switch (relay or MOSFET):
    Determine which physical pin on the autopilot board will be used as the GPIO (typically any unused PWM output channel can work).
    Find out the PWM pin number associated with the choosen physical pin, and set it as a GPIO pin:
    Mission Planner -> Config tab -> Full Parameter List -> set SERVOn_FUNCTION as -1, where n is the PWM pin number (i.e. the output channel number),
    e.g., FMU PWM Output pin 8 on the Holybro 6C autopilot board is output channel number 16, which maps to SERVO16 as seen at https://ardupilot.org/copter/docs/common-holybro-pixhawk6C.html#gpios
    Note: the GPIO logic level high voltage corresponds to that of the board (for Holybro 6C, 3.3V)

 4) Identify the GPIO pin number:
    Consult the autopilot's hardware definition (hwdef.dat) or the ArduPilot GPIO documentation (https://ardupilot.org/copter/docs/common-holybro-pixhawk6C.html#gpios)
    to find the GPIO pin number which corresponds to the output channel number, e.g., output channel number 15 corresponds to GPIO 56.
    Set this script's 'GPIO_PIN' variable to the GPIO pin number.

 5) Put this script in the 'script' folder on the autopilot board's SD card:
    Mission Planner -> Config Tab -> MAVFtp tab -> Navigate the Folder Tree [(unnamed folder) -> APM -> scripts] -> Right click, select upload -> upload this script

Created by Bradley Canty, 2025/11/25

Notes:
* pixhawk cube orange quadcopter variables:
  - INPUT_CHANNEL = 7
  - GPIO_PIN      = 50, which corresponds to output channel 9

* pixhawk HolyBro 6C quadcopter variables:
  - INPUT_CHANNEL = 7
  - GPIO_PIN   = 57, which corresponds to output channel 16 (aux pin 8)

TO DO:


--]]

local INPUT_CHANNEL = 7 --the TX switch's channel number
local GPIO_PIN = 50  --the GPIO pin number corresponding to the output channel
local PWM_THRESHOLD_HIGH = 1800 --PWM value for 'ON' state
local PWM_THRESHOLD_LOW = 1200  --PWM value for 'OFF' state
local timer = 0

function init()
    gcs:send_text(6,"Initializing position_leds.lua script...")
    gpio:pinMode(GPIO_PIN, 1) --set the GPIO pin as an output
    gpio:write(GPIO_PIN,0) --set GPIO pin to logic level LOW
    return true
end

function update()
    local rc_input = rc:get_pwm(INPUT_CHANNEL)
    --gcs:send_text(6, "rc_pwm = " .. tostring(rc_input))

    if (rc_input > PWM_THRESHOLD_HIGH) then
        if (timer == 0) then
            gpio:write(GPIO_PIN,1) --set GPIO pin to logic level HIGH
        elseif (timer == 1) then
            gpio:write(GPIO_PIN,0) --set GPIO pin to logic level LOW
        elseif (timer == 2) then
            gpio:write(GPIO_PIN,1)
        elseif (timer == 3) then
            gpio:write(GPIO_PIN,0)
        end

    elseif (rc_input < PWM_THRESHOLD_LOW) then
        gpio:write(GPIO_PIN,0) --set GPIO pin to logic level LOW
        timer = 0
    end

    timer = timer + 1
    if (timer == 15) then
        timer = 0
    end

    return update, 100 --update every 100ms in an infinite loop
end

init()

--Schedule the function to run for the first time 0ms after script load
--return update, 0 --working
return update, 1000
