
/* Holds the stable position of Gyro and Acc */


int xy_max, xy_min;
int stabilityIterations;
int begStab[3][100];

int accx[2], posx[2], velx[2];
float startTime, loopTime;
int count2;
float sensitivity, sensitivityAcc;

/* Holds values calculated for Gyros such as Filter const and Timers */

float freq;
double tau_constant, HPF_constant, LPF_constant;
double dt;


void setup(){
    
    Serial.begin(115200);
    
      stabilityIterations = 50;          // Increase if ISSUES persist
      
      xy_min = 1000;                    // min value for Acc
      xy_max = 0;                      // max value for Acc
      count2 = 0;


sensitivityAcc = ( 0.33 / 3.3 ) * 1023;  

 // startTime = millis();
    stableLocAcc();
    

}  

void loop(){
  

   
 loopTime = ( millis() - startTime );
  startTime = millis();

  //Serial.println(( analogRead(A1) - xy_max ) / (float)sensitivityAcc);
  
  for ( int i = 0; i < 3; i ++)
   {
    accx[1] = accx[1] + analogRead(A1);
    }
    
   accx[1] = accx[1]/3;

   accx[1] = accx[1] - xy_max;
   if ( accx[1] <= 3 && accx[1] >= -3 )      // Fixes discrimanation window error
         accx[1] = 0;
  
  
  velx[1] = velx[0] + accx[0] + ( (accx[1] - accx[0])/2 );
  posx[1] = posx[0] + velx[0] + ( (velx[1] - velx[0])/2 );

  
  accx[0] = accx[1];
  velx[0] = velx[1];
  

  
  finalMovCheck();
  

  posx[0] = posx[1];
  
  
  
  Serial.println(loopTime);
///Serial.println( ( posx[1] / sensitivityAcc ) * ( 980 ) * loopTime*loopTime  );
/*
  Serial.print("Pos    ,");
  Serial.print((posx[1] / 0.330) * 0.0098);
  Serial.print(",      Vel:    ,");
  Serial.print(velx[1]);
  Serial.print(",       Acc:     ,");
  Serial.println(accx[1]);
  */
 delay(100);
 
  

}


void finalMovCheck(){
 
   if ( accx[1] == 0 )
       {
         count2++;
       }
    else
       {
         count2 = 0;
       }
   if (count2 >= 3)
      {
         velx[1] = 0;
         velx[0] = 0;
      } 
  
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
