/*
THIS PROGRAM WORKS WITH PulseSensorAmped_Arduino-xx ARDUINO CODE
THE PULSE DATA WINDOW IS SCALEABLE WITH SCROLLBAR AT BOTTOM OF SCREEN
PRESS 'S' OR 's' KEY TO SAVE A PICTURE OF THE SCREEN IN SKETCH FOLDER (.jpg)
MADE BY JOEL MURPHY AUGUST, 2012
*/


import processing.serial.*;
PFont font;
Scrollbar scaleBar;

Serial port;     

int Sensor;      // HOLDS PULSE SENSOR DATA FROM ARDUINO
int IBI;         // HOLDS TIME BETWEN HEARTBEATS FROM ARDUINO
int BPM;         // HOLDS HEART RATE VALUE FROM ARDUINO
int[] RawY;      // HOLDS HEARTBEAT WAVEFORM DATA BEFORE SCALING
int[] ScaledY;   // USED TO POSITION SCALED HEARTBEAT WAVEFORM
int[] rate;      // USED TO POSITION BPM DATA WAVEFORM
float zoom;      // USED WHEN SCALING PULSE WAVEFORM TO PULSE WINDOW
float offset;    // USED WHEN SCALING PULSE WAVEFORM TO PULSE WINDOW
color eggshell = color(255, 253, 248);
int heart = 0;   // This variable times the heart image 'pulse' on screen
//  THESE VARIABLES DETERMINE THE SIZE OF THE DATA WINDOWS
int PulseWindowWidth = 490;
int PulseWindowHeight = 512; 
int BPMWindowWidth = 180;
int BPMWindowHeight = 340;
boolean beat = false;    // set when a heart beat is detected, then cleared when the BPM graph is advanced

Table table;
Table table_single;
JSONArray values;
XML xml;
XML xml_single;
int id_counter;

void setup() {
  size(700, 600);  // Stage size
  frameRate(100);  
  font = loadFont("Arial-BoldMT-24.vlw");
  textFont(font);
  textAlign(CENTER);
  rectMode(CENTER);
  ellipseMode(CENTER);  
// Scrollbar constructor inputs: x,y,width,height,minVal,maxVal
  scaleBar = new Scrollbar (400, 575, 180, 12, 0.5, 1.0);  // set parameters for the scale bar
  RawY = new int[PulseWindowWidth];          // initialize raw pulse waveform array
  ScaledY = new int[PulseWindowWidth];       // initialize scaled pulse waveform array
  rate = new int [BPMWindowWidth];           // initialize BPM waveform array
  zoom = 0.75;                               // initialize scale of heartbeat window
    
// set the visualizer lines to 0
 for (int i=0; i<rate.length; i++){
    rate[i] = 555;      // Place BPM graph line at bottom of BPM Window 
   }
 for (int i=0; i<RawY.length; i++){
    RawY[i] = height/2; // initialize the pulse window data line to V/2
 }
   
// GO FIND THE ARDUINO
  println(Serial.list());    // print a list of available serial ports
  // choose the number between the [] that is connected to the Arduino
  port = new Serial(this, Serial.list()[0], 115200);  // make sure Arduino is talking serial at this baud rate
  port.clear();            // flush buffer
  port.bufferUntil('\n');  // set buffer full flag on receipt of carriage return
  
// SET UP TABLE TO SAVE BPM DATA WITH CORRESPONDING ID AND TIME
  table = new Table();
  table.addColumn("id");
  table.addColumn("hour");
  table.addColumn("minute");
  table.addColumn("second");
  table.addColumn("ms");
  table.addColumn("BPM");
  saveTable(table, "data/bpm_data.csv");
  saveTable(table, "data/bpm_data_single.csv");

  values = new JSONArray();
  JSONObject header_row = new JSONObject();
  values.setJSONObject(0, header_row);
  saveJSONArray(values, "data/bpm_data.json");
  
  // PREP (CLEAR) XML CHARTS
  xml = loadXML("web/bpm_data.xml");
  xml_single = loadXML("web/bpm_data_single.xml");
  XML[] children = xml.getChildren("datapoint");
  XML[] children_single = xml_single.getChildren("datapoint");
  for(int i = 0; i < children.length; i++)
  {
    XML element = xml.getChild("datapoint");
    xml.removeChild(element);
  }
  for(int i = 0; i < children_single.length; i++)
  {
    XML element = xml_single.getChild("datapoint");
    xml_single.removeChild(element); 
  }
  saveXML(xml, "web/bpm_data.xml");
  saveXML(xml_single, "web/bpm_data_single.xml");
  // PREP (CLEAR) XML CHARTS
  
  
  println("setup() complete");

}
  
void draw() {
  background(0);
  noStroke();
// DRAW OUT THE PULSE WINDOW AND BPM WINDOW RECTANGLES  
  fill(eggshell);  // color for the window background
  rect(255,height/2,PulseWindowWidth,PulseWindowHeight);
  rect(600,385,BPMWindowWidth,BPMWindowHeight);
  
// DRAW THE PULSE WAVEFORM
  // prepare pulse data points    
  RawY[RawY.length-1] = (1023 - Sensor) - 212;   // place the new raw datapoint at the end of the array
  zoom = scaleBar.getPos();                      // get current waveform scale value
  offset = map(zoom,0.5,1,150,0);                // calculate the offset needed at this scale
  for (int i = 0; i < RawY.length-1; i++) {      // move the pulse waveform by
    RawY[i] = RawY[i+1];                         // shifting all raw datapoints one pixel left
    float dummy = RawY[i] * zoom + offset;       // adjust the raw data to the selected scale
    ScaledY[i] = constrain(int(dummy),44,556);   // transfer the raw data array to the scaled array
  }
  stroke(250,0,0);                               // red is a good color for the pulse waveform
  noFill();
  beginShape();                                  // using beginShape() renders fast
  for (int x = 1; x < ScaledY.length-1; x++) {    
    vertex(x+10, ScaledY[x]);                    //draw a line connecting the data points
  }
  endShape();
  
// DRAW THE BPM WAVE FORM
// first, shift the BPM waveform over to fit then next data point only when a beat is found
 if (beat == true){   // move the heart rate line over one pixel every time the heart beats 
   beat = false;      // clear beat flag (beat flag waset in serialEvent tab)
   for (int i=0; i<rate.length-1; i++){
     rate[i] = rate[i+1];                  // shift the bpm Y coordinates over one pixel to the left
   }
// then limit and scale the BPM value
   BPM = min(BPM,200);                     // limit the highest BPM value to 200
   float dummy = map(BPM,0,200,555,215);   // map it to the heart rate window Y
   rate[rate.length-1] = int(dummy);       // set the rightmost pixel to the new data point value
 } 
 // GRAPH THE HEART RATE WAVEFORM
 stroke(250,0,0);                          // color of heart rate graph
 strokeWeight(2);                          // thicker line is easier to read
 noFill();
 beginShape();
 for (int i=0; i < rate.length-1; i++){    // variable 'i' will take the place of pixel x position   
   vertex(i+510, rate[i]);                 // display history of heart rate datapoints
 }
 endShape();
 
// DRAW THE HEART AND MAYBE MAKE IT BEAT
  fill(250,0,0);
  stroke(250,0,0);
  // the 'heart' variable is set in serialEvent when arduino sees a beat happen
  heart--;                    // heart is used to time how long the heart graphic swells when your heart beats
  heart = max(heart,0);       // don't let the heart variable go into negative numbers
  if (heart > 0){             // if a beat happened recently, 
    strokeWeight(8);          // make the heart big
  }
  smooth();   // draw the heart with two bezier curves
  bezier(width-100,50, width-20,-20, width,140, width-100,150);
  bezier(width-100,50, width-190,-20, width-200,140, width-100,150);
  strokeWeight(1);          // reset the strokeWeight for next time


// PRINT THE DATA AND VARIABLE VALUES
  fill(eggshell);                                       // get ready to print text
  text("Pulse Sensor Amped Visualizer 1.1",245,30);     // tell them what you are
  text("IBI " + IBI + "mS",600,585);                    // print the time between heartbeats in mS
  text(BPM + " BPM",600,200);                           // print the Beats Per Minute
  text("Pulse Window Scale " + nf(zoom,1,2), 150, 585); // show the current scale of Pulse Window 
  
// PRINTS REACTION LEVELS BASED ON THRESHOLD LEVELS
  String threshold = "test";
  if(BPM==0) {
    threshold = "FLATLINE!";
  }
  else if(BPM > 0 && BPM < 67) {
    threshold = "Resting";
  }
  else if(BPM >= 67 && BPM < 75) {
   threshold = "Walking"; 
  }
  else if(BPM >= 75 && BPM < 100) {
   threshold = "Low Exertion";
  }
  else if(BPM >= 100 && BPM < 170) {
   threshold = "Target Zone";
  } 
  else if(BPM >= 170 && BPM <= 200) {
   threshold = "Danger!";
  }
  text(threshold, 600, 100);
  
  int id_num = id_counter;
  int hour_num = hour();
  int minute_num = minute();
  int second_num = second();
  int millis_num = millis();
/* 
// SAVE BPM IN "data/bpm_data.csv"
  table = loadTable("data/bpm_data.csv", "header");
  table_single = loadTable("data/bpm_data_single.csv", "header");
  TableRow newRow = table.addRow();
  TableRow newSingleRow = table_single.getRow(0);
  int id_num = table.getRowCount() - 1;
  newRow.setInt("id", id_num );
  newRow.setInt("hour", hour_num);
  newRow.setInt("minute", minute_num);
  newRow.setInt("second", second_num);
  newRow.setInt("ms", millis_num);
  newRow.setInt("BPM", BPM);
  newSingleRow.setInt("id", id_num );
  newSingleRow.setInt("hour", hour_num);
  newSingleRow.setInt("minute", minute_num);
  newSingleRow.setInt("second", second_num);
  newSingleRow.setInt("ms", millis_num);
  newSingleRow.setInt("BPM", BPM);
  saveTable(table, "data/bpm_data.csv");
  saveTable(table_single, "data/bpm_data_single.csv");
  
  JSONArray values = loadJSONArray("data/bpm_data.json");
  JSONObject bpm_obj = new JSONObject();
  bpm_obj.setInt("id", id_num);
  bpm_obj.setInt("hour", hour_num);
  bpm_obj.setInt("minute", minute_num);
  bpm_obj.setInt("second", second_num);
  bpm_obj.setInt("ms", millis_num);
  bpm_obj.setInt("BPM", BPM);
  values.setJSONObject(id_num, bpm_obj);
  saveJSONArray(values, "data/bpm_data.json");
  saveJSONObject(bpm_obj, "data/bpm_data_single.json");
*/
  
 /*
  xml = loadXML("data/bpm_data.xml");
  XML xml_inner_element = xml.getChild("datapoint");
  println(xml_inner_element.getInt("id"));
  XML hour_element = xml_inner_element.getChild("hour");
  println(hour_element.getIntContent());
  */
  
  xml = loadXML("web/bpm_data.xml");
  //xml_single = loadXML("web/bpm_data_single.xml");
  XML newChild = xml.addChild("datapoint");
  //XML newChildSingle = xml.addChild("datapoint");
  newChild.setInt("id", id_num);
  //newChildSingle.setInt("id", id_num);
  XML hour_elem = newChild.addChild("hour");
  //XML hour_elem_single = newChildSingle.addChild("hour");
  hour_elem.setContent(str(hour_num));
  //hour_elem_single.setContent(str(hour_num));
  XML minute_elem = newChild.addChild("minute");
  //XML minute_elem_single = newChildSingle.addChild("minute");
  minute_elem.setContent(str(minute_num));
  //minute_elem_single.setContent(str(minute_num));
  XML second_elem = newChild.addChild("second");
  //XML second_elem_single = newChildSingle.addChild("second");
  second_elem.setContent(str(second_num));
  //second_elem_single.setContent(str(second_num));
  XML ms_elem = newChild.addChild("ms");
  //XML ms_elem_single = newChildSingle.addChild("ms");
  ms_elem.setContent(str(millis_num));
  //ms_elem_single.setContent(str(millis_num));
  XML BPM_elem = newChild.addChild("BPM");
  //XML BPM_elem_single = newChildSingle.addChild("BPM");
  BPM_elem.setContent(str(BPM));
  //BPM_elem_single.setContent(str(BPM));
  saveXML(xml, "web/bpm_data.xml");
  //saveXML(xml_single, "web/bpm_data_single.xml");
  
//  DO THE SCROLLBAR THINGS
  scaleBar.update (mouseX, mouseY);
  scaleBar.display();
  
  id_counter++;
//   
}  //end of draw loop



