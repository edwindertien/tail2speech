//This example code is in the Public Domain (or CC0 licensed, at your option.)
//By Evandro Copercini - 2018
//
//This example creates a bridge between Serial and Classical Bluetooth (SPP)
//and also demonstrate that SerialBT have the same functionalities of a normal Serial


#include "GY_85.h"
#include <Wire.h>
GY_85 GY85;     //create the object

#include "BluetoothSerial.h"
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif
BluetoothSerial SerialBT;

void setup() {  
  Serial.begin(115200);

  SerialBT.begin("sensor-3"); //Bluetooth device name
  Serial.println("The device started, now you can pair it with bluetooth!");
  
  Wire.begin();
  delay(10);
  GY85.init();
  delay(10);
}
unsigned long looptime;
void loop() {
  
  int ax = GY85.accelerometer_x( GY85.readFromAccelerometer() );
  int ay = GY85.accelerometer_y( GY85.readFromAccelerometer() );
  int az = GY85.accelerometer_z( GY85.readFromAccelerometer() );
  if(ax>50000) ax=ax-65535;
  if(ay>50000) ay=ay-65535;
  if(az>50000) az=az-65535;
  //    int cx = GY85.compass_x( GY85.readFromCompass() );
  //    int cy = GY85.compass_y( GY85.readFromCompass() );
  //    int cz = GY85.compass_z( GY85.readFromCompass() );

//  int gx = GY85.gyro_x( GY85.readGyro() );
//  int gy = GY85.gyro_y( GY85.readGyro() );
//  int gz = GY85.gyro_z( GY85.readGyro() );
  //    float gt = GY85.temp  ( GY85.readGyro() );

if(millis()>looptime+9){
  looptime = millis();
  SerialBT.print  ( ax+512 );
  SerialBT.print  ( ',' );
  SerialBT.println  ( ay+512 );
  //SerialBT.print  ( ',' );
  //SerialBT.println  ( az+512 );
//  SerialBT.print  ( ',' );
//  SerialBT.print  ( gx );
//  SerialBT.print  (',');
//  SerialBT.print  ( gy );
//  SerialBT.print  (',');
//  SerialBT.println  ( gz );
  //SerialBT.println(analogRead(A0));
}
  
}
