#include "Wire.h"
#include "I2Cdev.h"
#include "MPU6050.h"

#define constGyroYaw 78.2609
#define HPF_constant 0.98
#define LPF_constant 0.02
#define isDebugON 1

   // Init the MPU library and variables
    MPU6050 accelgyro;
    int16_t ax, ay, az;
    int16_t gx, gy, gz;
    
   // Mushfiq Sarker - Algorithm Variables - PENDING FINALIZATION
    double previousXvalues[5], previousYvalues[5];
    float calculatedXang,calculatedYang;
    int totalLoop = 0;
    float startingAngX, startingAngY;
    double tempXval= 0, totalXval = 0, currentXval = 0, previousXval = 0;
    double tempYval= 0, totalYval = 0, currentYval = 0, previousYval = 0;
    int count_x, count_y,  Xinc, Yinc;
    float x_temp, y_temp;
    float finalAngleX, finalAngleY;

  // General Variables
    int stabilityIterations;
    double startTime, loopTime;

  // DataPerSecond() calculation variables
    double inc;
    float counter;
    
  // stableLocAcc() variables
    int begStab[3][100];
    float xy_max, xy_min;
    
  // getAccAngles() variables
    double quadrant_x, quadrant_y;
    float accXoffset, accZoffset , accYoffset;
    
  // calibrateZeroes() variables
    float gyroZeroRoll, gyroZeroPitch, gyroZeroYaw;
  
  // Retreive Gyro and Acc variables
    float acc_x, acc_y, acc_z;
    float newGyroPitch, newGyroRoll, newGyroYaw;
    float angleX, angleY, angleZ;

  // Final angles with true rotational measurement
    float calculatedZang;



void setup() {

    Wire.begin();                     // begin the Wire class for I2C
    Serial.begin(38400);              // Baudrate set at 38400 (can be changed)
  
    stabilityIterations = 100;        // number of times to loop to get stable acc values
    xy_min = 1000;                    // min value for Acc
    xy_max = 0;                      // max value for Acc
    loopTime = 0;  

  // Intialize the MPU6000 device
      accelgyro.initialize();
      Serial.println(accelgyro.testConnection() ? "MPU6000 connection successful" : "MPU6000 connection failed");

  // calculate the stable locations for Gyroscope and Accelerometer
      stableLocAcc();
      calibrateZeroes();
      
  // start the clock  
    startTime = millis();
    
    delay(10);
}

void loop() {

  //DataPerSecond();
  
  loopTime = (millis() - startTime) * 0.001;       // recalculate how long it took finish loop and calculate it
  startTime = millis();

      fullRotationYaw();        // take angleZ and calculate full rotation Yaw (0 to 360 degrees), returns calculatedZang
      stabilizeAngleValues();    // Stores recalculatre X and Y values in calculatedXang and calculatedYang

 /*

      Serial.print("X angle:");
      Serial.print("\t");
      Serial.print(calculatedXang  );
      Serial.print("\t");
      /*Serial.print("     Y angle:      ");
      Serial.print("\t");
      Serial.print(calculatedYang );
      Serial.print("\t");*/
    /*  Serial.print("     Z angle:      ");
      Serial.print("\t");
      Serial.println(calculatedZang );
      */

}



/*  Method - FullRotationYaw() 
*   Description - Calculate 360 degree rotation based on Gyro Yaw Rate
*   Parameters - none
*   Return - none
*   Values updated - calculatedZang
*/
void fullRotationYaw()
{

  // if the GYRO rate is neg (yaw turn RIGHT) 
  // turn it into positive (abs) because RIGHT means positive degree
  // if GYRO rate (angleZ) is positive (yaw turn LEFT)
  // subtract abs of angle by 360 to decrease angle (360--)
  // Now if new calculated Gyro angle is 360 then reset so we can start over.

  // @see - constGyroYaw - at 1.15 Gyro rate we want 90 degrees so 90/1.15 = constGyroYaw

      gz = accelgyro.getRotationZ();                                       // retrieve YawZ value from MPU6000
      newGyroYaw =  ( ( ( ( gz - gyroZeroYaw ) / 16.4 ) * loopTime ) );    // Gyro YAW rate/degree (16.4 is senstivity at 2000 degs/sec - Check Datasheet)
      angleZ =  angleZ + newGyroYaw * ( loopTime ) ;                      // do a numerical integration of all Yaw values

      if ( angleZ < 0)
        calculatedZang = abs(angleZ * constGyroYaw);
      else
        calculatedZang = 360 - abs(angleZ * constGyroYaw);
    
      if ( calculatedZang == 360)
        calculatedZang = 0;

  // calculatedZang is updated with new value!

}


/*  Method - getAccAngles() 
*   Description - calculate Acc X and Y rotation.
*   Parameters - none
*   Return - none
*   Values updated - acc_x, acc_y
*/
void getAccAngles()
{
    // accX,Y,Zoffset contains new value minus gravity * (1/8192). 
    // 8192 LSB/g is from datasheet with Acceleromter set to -+4g's
    accXoffset = ( ax - xy_max ) * 0.000122;
    accYoffset = ( ay - xy_min ) * 0.000122;
    accZoffset = ( az - xy_max ) * 0.000122;

    // Determine which quadrant we are in
    // Checki Z and X RAW values to see quadrant and set quadrant offset to 0, 180, or 360.
    // Quadrant_x,y constants will be added to final angle in another part of the code.
      if ( accXoffset >= 0 && accZoffset >= 0 ) quadrant_x = 0; 
      if ( accXoffset > 0 && accZoffset < 0 )   quadrant_x = 180; 
      if ( accXoffset <= 0 && accZoffset <= 0 ) quadrant_x = 180; 
      if ( accXoffset < 0 && accZoffset > 0 )   quadrant_x = 360;
      
      if ( accYoffset >= 0 && accZoffset >= 0 ) quadrant_y = 0; 
      if ( accYoffset > 0 && accZoffset < 0 )   quadrant_y = 180; 
      if ( accYoffset <= 0 && accZoffset <= 0 ) quadrant_y = 180; 
      if ( accYoffset < 0 && accZoffset > 0 )   quadrant_y = 360;
      
    // calculate the angle with tan inverse of the X,Y to the Z value
    // 57.2957795 is constant from radians to Degrees.
      acc_x =  (atan( accXoffset / accZoffset )) * 57.2957795 ;
      acc_y =  (atan( accYoffset / accZoffset )) * 57.2957795;
  
    // returns updated acc_x and acc_y values
}

/*  Method - getGyroAngles() 
*   Description - calculate Gyro Roll and Pitch angles.
*   Parameters - none
*   Return - none
*   Values updated - newGyroPitch, newGyroRoll
*/
void getGyroAngles()
{
   // Example calculation
       // gx is degrees/second value from MPU6000
       // gyroZeroPitch is still Pitch value (gravity offset)
       // 1) subtract gx from gyroZeroPitch to remove gravity effect
       // 2) divide by sensitivity - according to datasheet at 2000 degs/sec it is 16.4 LSB/g
       // 3) gyro rate is degs/sec so multiple by the time it takes to execute one cycle LOOPTIME to get Degrees
    // Example complete
 
        newGyroPitch =  ( ( ( ( gx - gyroZeroPitch ) / 16.4 ) * loopTime ) );      // gyro_pitch is ADC value from gyro
        newGyroRoll =  ( ( ( ( gy - gyroZeroRoll ) / 16.4 ) * loopTime ) );         // gyro_roll is ADC value from gyro
    // NOTE: newGyroYaw is calculated in fullRotationYaw method

}

/*  Method - CalibrateZeroes() 
*   Description - calibrate Gyroscope values for offset gravity calculations
*   Parameters - none
*   Return - none
*   Values updated - gyroZeroYaw, gyroZeroPitch, gyroZeroRoll
*/
void calibrateZeroes()
{
    // run through 30 gyro values (X,Y,Z).
    // first 20 are disregarded because they are startup values and wrong
    // The 20th value to 29 (10 values) are all added
    // Afterwards they are divided by 10. AVERAGE gyro value used as Gravity offset subtraction
    for (int i=0;i<30;i++)
    {
      accelgyro.getRotation(&gx, &gy, &gz);
      if ( i>=20)
        {
          gyroZeroYaw += gz; //average 10 readings
          gyroZeroPitch += gx;
          gyroZeroRoll += gy;
        }
    }

  // AVG values
    gyroZeroYaw = gyroZeroYaw / 10;
    gyroZeroPitch = gyroZeroPitch/10;
    gyroZeroRoll= gyroZeroRoll/10;
    
  // Print for debugging
   if ( isDebugON)
     {
        Serial.print("ZeroYaw is ");
        Serial.println(gyroZeroYaw);
        Serial.print("ZeroPitch is ");
        Serial.println(gyroZeroPitch);
        Serial.print("ZeroRoll is ");
        Serial.println(gyroZeroRoll);
     }
}

/*  Method - stableLocAcc() 
*   Description - calibrate Accelerometer values for offset gravity calculations
*   Parameters - none
*   Return - none
*   Values updated - gyroZeroYaw, gyroZeroPitch, gyroZeroRoll
*/
void stableLocAcc()
{

   // StabilityIterations - set in SETUP method above (100 usually)
   // go through for loop and retrieve Acceleration (X, Y, Z)
   // store value into array [0][a] is X value, [1][a] is Y value
   // skip the first 10 values because it is garbage values
      for ( int a = 0 ; a < stabilityIterations - 1; a++) 
        {
            accelgyro.getAcceleration(&ax, &ay, &az);
            begStab[0][a] = ax;
            begStab[1][a] = ay;
          
          // after 10th value, check for MAX and MIN values via IF statements
          // Save to global variables XY_MIN and XY_MAX
          // Gravity accelerometer offset values are XY_MIN and XY_MAX
            if ( a >= 10 )
              {
                if ( xy_min > begStab[1][a]) 
                  xy_min = begStab[1][a];          // used for gravity subtraction on Y axis
          
                if ( xy_max < begStab[0][a] )
                  xy_max = begStab[0][a];          // used for gravity subtraction on X axis
              }
          delay(10);
        }
        
    // Print for debugging
    if ( isDebugON )
      {
        Serial.print("Max is ");
        Serial.println(xy_max);
        Serial.print("Min is ");
        Serial.println(xy_min);
      }

}


/* Method - DataPerSecond()
*  Description - retrieve number of data per second. For benchmark tests. Place method in LOOP to get test results
*/
void DataPerSecond()
{
  if ( loopTime < 0.1) inc = inc + loopTime;

  counter++;

  if ( inc >= 1)
  {
    Serial.println(counter);
    inc = 0;
    counter = 0;
  }

}



/* Method - stabilizeAngleValues()
*  Description - Mushfiq Sarker Algorithm for stabilizing Pitch and Roll angles. WORK PENDING NOT DONE
*
*/
void stabilizeAngleValues()
{
      if ( Xinc == 5 ) Xinc = 0;
      if ( Yinc == 5) Yinc = 0;
    
      for ( int i = 0; i < 4; i++)
        {
          accelgyro.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
          getGyroAngles();                // calculate the Gyro Angles
          getAccAngles(); 
    
          angleX =  ( HPF_constant ) * ( angleX + newGyroPitch * ( loopTime ) )  + ( LPF_constant ) * ( acc_x )  ;
          finalAngleX = angleX + quadrant_x;
    
          angleY = ( HPF_constant ) * ( angleY + newGyroRoll * ( loopTime ) )  + ( LPF_constant ) * ( acc_y );
          finalAngleY = angleY + quadrant_y;
    
    
            if ( i == 0  ) 
            {
              currentXval = finalAngleX;
              currentYval = finalAngleY;
            }
    
    
        
            if ( currentXval < ( previousXval + 0.1*previousXval) && currentXval > ( previousXval - 0.1*previousXval)  )
            {
              if ( (currentXval) > (finalAngleX-3)  && (currentXval) < (finalAngleX+3) && ( finalAngleX >=0 && finalAngleX <= 360) )
              {
                //  Serial.print( finalAngleX);
                //Serial.print("     ");
                tempXval = tempXval + finalAngleX;
                totalXval++;
              }
            }         
            else
              if ( currentXval >= 0 )
                previousXval = currentXval;
    
    
    
        if ( currentYval < ( previousYval + 0.1*previousYval) && currentYval > ( previousYval - 0.1*previousYval)  )
        {
          if ( (currentYval) > (finalAngleY-3)  && (currentYval) < (finalAngleY+3) && ( finalAngleY >=0 && finalAngleY <= 360) )
          {
            //  Serial.print( finalAngleY);
            //Serial.print("     ");
            tempYval = tempYval + finalAngleY;
            totalYval++;
          }
        }         
        else
          if ( currentYval >= 0 )
            previousYval = currentYval;
    
    
      } 
    
      // number of data points ! = 0 then save the data into array
      // The array will hold 5 most recent values and compare them below
      if ( totalXval != 0 )        
      {
        previousXvalues[Xinc] = tempXval / totalXval;   
      }  
    
      if ( totalYval != 0 )        
      {
        previousYvalues[Yinc] = tempYval / totalYval;
      }  
    
      // Interpolation
      // Go through the 5 values stored in the array and check the new value to safety margin (10%).
      // If not within range, then ignore and calculate avg value of save valudes and that is the new value.
      for ( int i = 0; i < 5; i++)
      {
        if ( previousXval <= (previousXvalues[i] + previousXvalues[i]*0.1) && previousXval >= (previousXvalues[i] - previousXvalues[i]*0.1)  )
        {
          // in range
          x_temp =  x_temp + previousXvalues[i];
          count_x++;
        }
    
        if ( previousYval <= (previousYvalues[i] + previousYvalues[i]*0.1) && previousYval >= (previousYvalues[i] - previousYvalues[i]*0.1)  )
        {
          // in range
          y_temp =  y_temp + previousYvalues[i];
          count_y++;
        }
      }
    
      // if count is zero then we know that no values are nearby so ignore.
      if ( count_x != 0 )
      {
        if ( count_x == 5)                  // We know new X value is within range so keep it
          calculatedXang = tempXval / totalXval;
        else
          calculatedXang = x_temp / count_x;
    
      }
    
    
      if ( count_y != 0 )
      {
        if ( count_y == 5)                  // We know new Y value is within range so keep it
          calculatedYang = tempYval / totalYval;
        else
          calculatedYang = y_temp / count_y;
    
      }
    

  tempXval = 0; totalXval = 0;  currentXval = 0; count_x = 0; x_temp = 0; Xinc++;
  tempYval = 0; totalYval = 0;  currentYval = 0; count_y = 0; y_temp = 0;Yinc++;

}

