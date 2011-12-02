#include <Wire.h>
int quadrant_x1, quadrant_x2, quadrant_x3;
/* Holds Raw Gyro and Acc data from Analog Ports */
float gyro_pitch, acc_x;
float gyro_roll, acc_y;
float gyro_yaw, acc_z;
double quadrant_x, quadrant_y;

double previousXvalues[5], previousYvalues[5];


float lengthWrench;
float x_disp, y_disp, z_disp;

/* Holds the angle calculations */
double accXval, accYval, accZval;
float newGyroPitch, newGyroRoll, newGyroYaw;

/* Holds the stable position of Gyro and Acc */
float gyroZeroRoll, gyroZeroPitch, gyroZeroYaw;
int xy_max, xy_min;

/* Holds the sensitivity for both Gyro and Acc */
double sensitivity, sensitivityAcc;
int stabilityIterations;

/* Holds values calculated for Gyros such as Filter const and Timers */
double startTime, loopTime;
double tau_constant, HPF_constant, LPF_constant;
double dt;

/* Holds array values for Stab Acc pos and Gyro Data in bytes */
byte data[6];      
int begStab[3][100];

/* Holds the fully calculated Gyro and Acc combined */
float angleX, angleY, angleZ;

float sensitivityYaw;


double tempXval= 0, totalXval = 0, currentXval = 0, previousXval = 0;
double tempYval= 0, totalYval = 0, currentYval = 0, previousYval = 0;
int count_x, count_y,  Xinc, Yinc;

float x_temp, y_temp;
float finalAngleX, finalAngleY;
double inc;
float counter;

float calculatedXang,calculatedYang;


/* Setup the arduino */
void setup() {

  Serial.begin(115200);
  Wire.begin();

  /* Init the WM */
  wmpOn();             //turn WM+ on
  calibrateZeroes();   //calibrate zeroes for gyro

  gyroZeroRoll = 0;

  /* Init the variables for Acc Stabilization */

  lengthWrench = 31.8516;  // Lenght of wrench is 25.4 cm (10 inches)
    
    
  xy_min = 1000;                    // min value for Acc
  xy_max = 0;                      // max value for Acc
  stabilityIterations = 100.0;    // do 100 Iterations to find stable acc value


  /* Init of Variables for Gyro */
  dt = 0.02;                  // Loop runs at 250 Hz when printing. (400hZ when not printing). so dt = 0.004 for 250 Hz
  tau_constant = 0.7;          // constant to determine value of filter. We pick this value
  loopTime = 0;                // init the times


  /* Gyro and Acc sensitivty calculations */
    sensitivity = 0.7037;      // from Gyro Datasheet math = ( ( 2.27 / 1000 ) / 3.3 ) * 1023
   // sensitivity = 0.155;                 // from Gyro Datasheet math = ( ( ( 0.5 / 1000 ) / 3.3 ) * 1023 )
    sensitivityAcc = 102.3;              // From ADXL335 Datasheet  math = ( 0.33 / 3.3 ) * 1023
  
  // Filter Constants
    HPF_constant = 0.98;
    LPF_constant = 0.02;

  /* Get the current millisecond time */
  startTime = millis();

  /* calculate the Acc stable spots */
    stableLocAcc();

  delay(100);

}

int totalLoop = 0;
float startingAngX, startingAngY;

void loop() {

  /*    LOOP runs at 250 Hz with Serial.println
   *    LOOP runs at 400 Hz without any serial.println
   */

     DataPerSecond();

  loopTime = (millis() - startTime) * 0.001;       // recalculate how long it took finish loop and calculate it
  startTime = millis();
  
  if ( Xinc == 5 ) Xinc = 0;
  if ( Yinc == 5) Yinc = 0;

      for ( int i = 0; i < 4; i++)
        {
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
    
    
    /*
    if ( totalLoop == 40)
      {
         startingAngX = calculatedXang;
        startingAngY = calculatedYang; 
      }
    if (totalLoop < 41)
      totalLoop++;
      */
      
   /*
     Serial.print("X pos:      ");
    Serial.print(startingAngX);
    Serial.print("     Y pos:      ");
    Serial.println(startingAngX);
    */
    
    /*
    Serial.print("X angle:      ");
    Serial.print(calculatedXang - startingAngX );
    Serial.print("     Y angle:      ");
    Serial.println(calculatedYang - startingAngY);
    */
    
    /*
      Serial.print("X angle:      ");
    Serial.print(previousXval );
    Serial.print("     Y angle:      ");
    Serial.println(calculatedXang );
    */
    
      x_disp = lengthWrench * ( 1 - cos( (calculatedXang) * (PI/180) ));
      y_disp = lengthWrench * sin( (calculatedYang) * (PI/180) );
    
   
    Serial.print("Y ang:      ");
    Serial.print(calculatedXang);
    
    Serial.print("     Y pos:      ");
    Serial.println(x_disp);
    
    
    
     
  tempXval = 0; totalXval = 0;  currentXval = 0; count_x = 0; x_temp = 0;
  Xinc++;
  
  tempYval = 0; totalYval = 0;  currentYval = 0; count_y = 0; y_temp = 0;
  Yinc++;


 //delay(0);
}




/************************************************************************ Gyro Code ************************************************************************/
void wmpOn()
{  
  Wire.beginTransmission(0x53); //WM+ starts out deactivated at address 0x53
  Wire.send(0xfe); //send 0x04 to address 0xFE to activate WM+
  Wire.send(0x04);
  Wire.endTransmission(); //WM+ jumps to address 0x52 and is now active
}

void wmpSendZero()
{
  Wire.beginTransmission(0x52); //now at address 0x52
  Wire.send(0x00); //send zero to signal we want info
  Wire.endTransmission();
}

void calibrateZeroes()
{
  for (int i=0;i<10;i++)
  {
    wmpSendZero();
    Wire.requestFrom(0x52,6);

    for (int i=0;i<6;i++)
    {
      data[i]=Wire.receive();
    }

    gyroZeroYaw+=(((data[3]>>2)<<8)+data[0])/10; //average 10 readings
    gyroZeroPitch+=(((data[4]>>2)<<8)+data[1])/10;
    gyroZeroRoll+=(((data[5]>>2)<<8)+data[2])/10;


  }
  /* 
   Serial.print("Yaw0:");
   Serial.print(gyroZeroYaw);
   Serial.print(" Pitch0:");
   Serial.print(gyroZeroPitch);
   Serial.print(" Roll0:");
   Serial.println(gyroZeroRoll);
   */
}


void getGyroAngles()
{
  /* IDG-650 has 2.27mV sensitive per degree, use sensitivity var
   *
   */

  // Read gyro Values in here
  wmpSendZero();                     //send zero before each request
  Wire.requestFrom(0x52,6);          //request the six bytes from the WM+
  for (int i=0;i<6;i++)
  {
    data[i]=Wire.receive();      // Store the 6 bytes in DATA
  }
  gyro_yaw=((data[3]>>2)<<8)+data[0];
  gyro_pitch=((data[4]>>2)<<8)+data[1];
  gyro_roll=((data[5]>>2)<<8)+data[2];

  //Serial.println( loopTime*(  ( gyro_pitch - gyroZeroPitch ) / sensitivity ));
  /* Take the raw gyro values and convert to degrees. The new value should be NUMBER in DEGREES. */
  newGyroPitch =  ( ( ( ( gyro_pitch - gyroZeroPitch ) / sensitivity ) * loopTime ) / 1000);      // gyro_pitch is ADC value from gyro
  newGyroRoll =  ( ( ( ( gyro_roll - gyroZeroRoll ) / sensitivity ) * loopTime ) / 1000);         // gyro_roll is ADC value from gyro
  newGyroYaw =  ( ( ( ( gyro_yaw - gyroZeroYaw ) / sensitivity ) * loopTime ) / 1000);            // gyro_yaw is ADC value from gyro

  //Serial.println(newGyroPitch);


}


/************************************************************************ Acceloremeter Code ************************************************************************/


void getAccAngles()
{

 
  // 240, 241 is the STEADY STATE on the table Accelerometer value
  // Z axis wants max of X and Y to calcualte vector
  
  // GIVES ABSOLUTE POS - (45deg physcically is 45 on the serial command)
  accXval = ( analogRead(2) - 240 ) / (float)sensitivityAcc;
  accYval = ( analogRead(1) - 241 ) / (float)sensitivityAcc;
  accZval = ( analogRead(0) - 240) / (float)sensitivityAcc;


/*
  accXval = ( analogRead(2) - xy_max ) / (float)sensitivityAcc;
  accYval = ( analogRead(1) - xy_max ) / (float)sensitivityAcc;
  accZval = ( analogRead(0) - xy_max) / (float)sensitivityAcc;
*/

  if ( accXval >= 0 && accZval >= 0 )  {quadrant_x = 0; }
  if ( accXval > 0 && accZval < 0 )  {quadrant_x = 180; }
  if ( accXval <= 0 && accZval <= 0 )  {quadrant_x = 180; }
  if ( accXval < 0 && accZval > 0 )  {quadrant_x = 360;}


  if ( accYval >= 0 && accZval >= 0 )  {quadrant_y = 0; }
  if ( accYval > 0 && accZval < 0 )  {quadrant_y = 180; }
  if ( accYval <= 0 && accZval <= 0 )  {quadrant_y = 180; }
  if ( accYval < 0 && accZval > 0 )  {quadrant_y = 360;}


  //float forceVector = sqrt ( pow(accXval,2) + pow(accYval,2) + pow(accZval,2) );


  acc_x =  (atan( accXval / accZval )) * 57.2957795 ;
  acc_y =  (atan( accYval / accZval )) * 57.2957795;

}


void stableLocAcc()
{

  for ( int a = 0 ; a < stabilityIterations - 1; a++) 
  {

    begStab[0][a] = analogRead(A1);
    begStab[1][a] = analogRead(A2);


    if ( a >= 10 )
    {

      if ( xy_min > begStab[0][a] )
        xy_min = begStab[0][a];

      if ( xy_min > begStab[1][a]) 
        xy_min = begStab[1][a];

      if ( xy_max < begStab[0][a] )
        xy_max = begStab[0][a];

      if ( xy_max < begStab[1][a] )
        xy_max = begStab[1][a];  


    }


    delay(10);
  }
  
      Serial.print("Max is ");
   Serial.println(xy_max);
   Serial.print("Min is ");
   Serial.println(xy_min);
   

}



/************************************************************************ Print Code ************************************************************************/
void printFinalAngles()
{
  /* Serial.print(" angleX - ");
   Serial.print ( angleX );
   Serial.print ( "   "  );
   Serial.print ( " angleY - "  );
   Serial.print( angleY );
   Serial.print ( " angleZ - "  );
   Serial.println( angleZ );
   
   */

  Serial.print(" Y - ");
  Serial.print ( angleY );
  Serial.print ( "   "  );
  Serial.print ( "X - "  );
  Serial.print( angleX );
  Serial.print ( "   "  );
  // Serial.print ( "Z - "  );
  // Serial.println( angleZ );
  Serial.println();
}

void printAccRawValues()
{
  Serial.print(" acc X - ");
  Serial.print ( analogRead(2) );
  Serial.print ( "   "  );
  Serial.print ( " acc Y - "  );
  Serial.print( analogRead(1) );
  Serial.print ( " acc Z - "  );
  Serial.println( analogRead(0) );
}

void printGyroRawValues()
{
  Serial.print(" Yaw - ");
  Serial.print ( gyro_yaw );
  Serial.print ( "   "  );
  Serial.print ( " Pitch - "  );
  Serial.print( gyro_pitch );
  Serial.print ( " Roll - "  );
  Serial.println( gyro_roll );
}

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
