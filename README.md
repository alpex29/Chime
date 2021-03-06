## Chime.

_Chime_ is time scheduler verticle which works on [Vert.x](http://vertx.io/) event bus and provides:  
* scheduling with _cron-style_, _interval_, _union_ or _custom_ timers:  
	* at a certain time of day (to the second)  
	* on certain days of the week, month or year  
	* with a given time interval  
	* with nearly any combination of all of above  
	* repeating a given number of times  
	* repeating until a given time / date  
	* repeating infinitely  
* proxying event bus with conventional interfaces  
* applying time zones available on _JVM_  
* flexible timers management system:  
	* grouping timers  
	* defining a timer start or end time  
	* pausing / resuming  
	* fire counting  
* listening and sending messages via event bus with _JSON_
* _publishing_ or _sending_ timer fire event to the address of your choice  

_Chime_ is written in [Ceylon](https://ceylon-lang.org) and is available at
[Ceylon Herd](https://herd.ceylon-lang.org/modules/herd.schedule.chime)  

> Runs with Ceylon 1.3.2 and Vert.x 3.4.1  


## Usage and documentation.  

1. Deploy _Chime_ verticle  
2. Create and listen timers on _EventBus_, see details in [API docs](https://modules.ceylon-lang.org/repo/1/herd/schedule/chime/0.2.0/module-doc/api/index.html)  

> _Chime_ communicates over event bus with `Json` messages.  
  Complete list of messages is available [here](../../wiki/Messages) 

Examples:  
* [with Ceylon](examples/herd/examples/schedule/chime)  
* [with Java and Maven](https://github.com/LisiLisenok/ChimeJavaExample)  
 

[Blog post at Vert.x website](http://vertx.io/blog/time-scheduling-with-chime/)  
