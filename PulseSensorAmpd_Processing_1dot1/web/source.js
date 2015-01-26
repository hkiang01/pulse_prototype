function my_function() {
   // https://stackoverflow.com/questions/26571975/reading-an-external-xml-file-with-jquery
  	//https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
  	if(window.XMLHttpRequest)
  	{
  		xmlhttp = new XMLHttpRequest();

  	}
  	else
  	{
  		xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
  	}
  	xmlhttp.open("GET", "bpm_data.xml", false); //false for synchronous, true for asynchronous
  	xmlhttp.send();
  	xmlDoc = xmlhttp.responseXML;
  	var collection = xmlDoc.getElementsByTagName("datapoint");
  	console.log(collection); //for some reason this only works on Firefox (tested on 35.0)
  	for(var i=0; i < collection.length; i++)
  	{
  		console.log(collection.item(i));
  		//console.log(collection.item(i).children);
  		console.log("hour: " + collection.item(i).children[0].childNodes[0].data);
  		console.log("minute: " + collection.item(i).children[1].childNodes[0].data);
  		console.log("second: " + collection.item(i).children[2].childNodes[0].data);
  		console.log("ms: " + collection.item(i).children[3].childNodes[0].data);
  		console.log("BPM: " + collection.item(i).children[4].childNodes[0].data);
   }
}

function hello_world() {
 console.log("hello, world");
}