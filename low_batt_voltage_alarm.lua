--[[
low_batt_voltage_alarm.lua

Description:
    This activates a buzzer and flashes orange LEDs when the battery voltage reaches a certain threshold. 
    Alarm system functionality check is performed via transmitter switch linked to channel 8.

Steps:
 1) Enable scripting: 
    Mission Planner -> Config tab -> Full Parameter List -> set SCR_ENABLE as 1

 2) Choose a GPIO pin for sending the on/off signal to the switch (relay or MOSFET):
    Determine which physical pin on the autopilot board will be used as the GPIO (typically any unused PWM output channel can work).
    Find out the PWM pin number associated with the choosen physical pin, and set it as a GPIO pin:
    Mission Planner -> Config tab -> Full Parameter List -> set SERVOn_FUNCTION as -1, where n is the PWM pin number (i.e. the output channel number),
    e.g., FMU PWM Output pin 7 on the Holybro 6C autopilot board is output channel 15, which maps to SERVO15 as seen at https://ardupilot.org/copter/docs/common-holybro-pixhawk6C.html#gpios
    Note: the GPIO logic level high voltage corresponds to that of the board (for Holybro 6C, 3.3V)

 3) Identify the GPIO pin number:
    Consult the autopilot's hardware definition (hwdef.dat) or the ArduPilot GPIO documentation (https://ardupilot.org/copter/docs/common-holybro-pixhawk6C.html#gpios)
    to find the GPIO pin number which corresponds to the output channel number, e.g., output channel number 15 corresponds to GPIO 56.
    Set this script's 'GPIO_PIN' variable to the GPIO pin number.

 4) Put this script in the 'script' folder on the autopilot board's SD card:
    Mission Planner -> Config Tab -> MAVFtp tab -> Navigate the Folder Tree [(unnamed folder) -> APM -> scripts] -> Right click, select upload -> upload this script

Created by: Bradley Canty, 2025/11/25

Notes:
* pixhawk cube orange quadcopter variables:
  - INPUT_CHANNEL = 8
  - GPIO_PIN      = 51, which corresponds to output channel 10

* pixhawk HolyBro 6C quadcopter variables:
  - INPUT_CHANNEL = 8
  - GPIO_PIN      = 56, which corresponds to output channel 15 (aux pin 7)

TO DO:


--]]

local INPUT_CHANNEL = 8 --the TX switch's channel number, for testing alarm functionality
local GPIO_PIN = 51  --the GPIO pin number corresponding to the output channel
local PWM_THRESHOLD_HIGH = 1800 --PWM value for 'ON' state
--local PWM_THRESHOLD_LOW = 1200  --PWM value for 'OFF' state
local BATT_VOLT_THRESHOLD_LOW = param:get('BATT_LOW_VOLT')
local timer = 0

if BATT_VOLT_THRESHOLD_LOW == nil then
    gcs:send_text(0, "BATT_LOW_VOLT parameter not found!")
end

function init()
    gcs:send_text(6,"Initializing low_batt_voltage_alarm.lua script...")
    gpio:pinMode(GPIO_PIN, 1) --set the GPIO pin as an output
    gpio:write(GPIO_PIN,0) --set GPIO pin to logic level LOW
    gcs:send_text(6,"Current battery voltage is " .. tostring(battery:voltage(0)) .. "V")
    gcs:send_text(6,"BATT_LOW_VOLT parameter set to " .. tostring(BATT_VOLT_THRESHOLD_LOW) .. "V")
    return true
end

function update()
    local voltage = battery:voltage(0) --get voltage of the first battery instance
    local rc_input = rc:get_pwm(INPUT_CHANNEL)

    if (voltage <= BATT_VOLT_THRESHOLD_LOW or rc_input > PWM_THRESHOLD_HIGH) then
        if (timer == 0) then
            gpio:write(GPIO_PIN,1) --set GPIO pin to logic level HIGH
        elseif (timer == 1) then
            gpio:write(GPIO_PIN,0) --set GPIO pin to logic level LOW
        end
        
    else --voltage above threshold or alarm test switch set to low
        gpio:write(GPIO_PIN,0)
        timer = 0
    end

    timer = timer + 1
    if (timer == 2) then
        timer = 0
    end

    return update, 750 --update every 750ms in an infinite loop
end

init()

--Schedule the function to run for the first time 0ms after script load
--return update, 5000 --working
return update, 1000