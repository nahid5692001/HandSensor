int SER_Pin = 8;   //pin 14 on the 75HC595
int RCLK_Pin = 9;  //pin 12 on the 75HC595
int SRCLK_Pin = 10; //pin 11 on the 75HC595

//How many of the shift registers - change this
#define number_of_74hc595s 1 

//do not touch

int s0 = 12;
int s1 = 13;

#define numOfRegisterPins number_of_74hc595s * 8

boolean registers[numOfRegisterPins];

void setup(){
  Serial.begin(9600);
  
  
  
    pinMode(s0, OUTPUT);
  pinMode(s1, OUTPUT);

  digitalWrite(s0, LOW);
  digitalWrite(s1, LOW);
  
  pinMode(SER_Pin, OUTPUT);
  pinMode(RCLK_Pin, OUTPUT);
  pinMode(SRCLK_Pin, OUTPUT);

  //reset all register pins
  clearRegisters();
  writeRegisters();
  
  
}               

//set all register pins to LOW
void clearRegisters(){
  for(int i = numOfRegisterPins - 1; i >=  0; i--){
     registers[i] = LOW;
  }
} 

//Set and display registers
//Only call AFTER all values are set how you would like (slow otherwise)
void writeRegisters(){

  digitalWrite(RCLK_Pin, LOW);

  for(int i = numOfRegisterPins - 1; i >=  0; i--){
    digitalWrite(SRCLK_Pin, LOW);

    int val = registers[i];

    digitalWrite(SER_Pin, val);
    digitalWrite(SRCLK_Pin, HIGH);

  }
  digitalWrite(RCLK_Pin, HIGH);

}

//set an individual pin HIGH or LOW
void setRegisterPin(int index, int value){
  registers[index] = value;
}

int readVal0, readVal1;
void loop(){
  
             setRegisterPin(1, LOW);
            setRegisterPin(2, LOW);
            writeRegisters();
   
  
   digitalWrite(s0, HIGH);
  
  readVal0 = analogRead(A0);
  

   digitalWrite(s0, LOW);
  
   readVal1 = analogRead(A0);
  

    
    
    
    
    if ( readVal1 )
        {
            setRegisterPin(2, HIGH);
            writeRegisters(); 
        }
 
    if ( readVal0 )
        {
            setRegisterPin(1, HIGH);
            writeRegisters(); 
        } 
        
        
        Serial.print("S0");
        Serial.print("\t");
        Serial.print(readVal0);
        Serial.print("\t");
          Serial.print("S1");Serial.print("\t");
        Serial.println(readVal1);
       

 

}
