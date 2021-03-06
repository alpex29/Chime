
"
 _Chime_ is time scheduler verticle which works on [Vert.x](http://vertx.io/) event bus and provides:  
 * scheduling with _cron-style_, _interval_, _union_ or _custom_ timers:
 	* at a certain time of day (to the second);  
 	* on certain days of the week, month or year;  
 	* with a given time interval;  
 	* with nearly any combination of all of above;  
 	* repeating a given number of times;  
 	* repeating until a given time / date  
 	* repeating infinitely;  
 * proxying event bus with conventional interfaces  
 * applying time zones available on _JVM_;  
 * flexible timers management system:  
 	* grouping timers;  
 	* defining a timer start or end times;  
 	* pausing / resuming;  
 	* fire counting;  
 * listening and sending messages via event bus with _JSON_;  
 * _publishing_ or _sending_ timer fire event to the address of your choice.  
 
 > _Chime_ communicates over event bus with \`Json\` messages. Complete list of messages is available
   at [Github](https://github.com/LisiLisenok/Chime/blob/master/howto.md).  
 
 
 ## Content.  
 * [Running the Chime.](#running)  
 * [Configuration.](#configuration)  
 * [Scheduling.](#scheduling)  
 	* [Requests and responses.](#requests-and-responses)  
 	* [Scheduler.](#scheduler)  
 		* [Request.](#scheduler-request)  
 		* [Example.](#scheduler-example)  
 	* [Timer.](#timer)  
 		* [Request.](#timer-request)  
 		* [Unique timer name.](#unique-timer-name)  
 		* [Supported timers.](#supported-timers)  
 		* [Events.](#timer-events)  
 		* [Time zones.](#time-zones)  
 		* [Message source](#timer-message-source)
 		* [Example.](#timer-example)  
 	* [Scheduler and timer interfaces.](#scheduler-timer-interfaces)  
 	* [Error messages.](#error-messages)  
 * [Cron expression.](#cron-expression)  
 	* [Expression fields.](#cron-expression-fields)  
 	* [Special characters.](#cron-special-characters)  
 	* [Cron expression builder.](#cron-expression-builder)  
 
 
 ## <a name =\"running\"></a> Running the Chime.
 
 Deploy _Chime_ using `Verticle.deployVerticle` method:  
 
 		import io.vertx.ceylon.core {vertx}
 		import herd.schedule.chime {Chime}
 		Chime().deploy(vertx.vertx());
 
 Or with `vertx.deployVerticle(\"ceylon:herd.schedule.chime/0.2.1\");`
 but ensure that Ceylon verticle factory is available at class path.  
 
 
 ## <a name =\"configuration\"></a> Configuration.
 
 Following parameters could be specified in `JsonObject` verticle configuration:  
 		JsonObject {
 			
 			// Address _Chime_ listens to, default is \"chime\".
 			\"address\" -> String,
 			
 			// Tolerance in milliseconds used to compare actual and requested times.
 			// Default is 10 milliseconds.
 			\"tolerance\" -> Integer,
 			
 			// If `true` _Chime_ and schedulers event bus addresses have not to propagate across the cluster,
 			// i.e. _Chime_ has to listen only messages from this local node.
 			// If `false` _Chime_ has to listen all nodes in the cluster.
 			// Default is false.
 			\"local\" -> Boolean,
 			
 			// A list of modules with version to look the extensions as service providers. 
 			\"services\" -> JsonArray {
 				\"module name/module version\"
 			}
 		};
 
 
 ## <a name =\"scheduling\"></a> Scheduling.  
 
 _Chime_ operates by two structures: _timer_ and _scheduler_.  
 Timer is a unit which fires at a given time.
 While scheduler is a set or group of timers and provides following:    
 * creating and deleting timers;  
 * pausing / resuming all timers working within the scheduler;  
 * info on the running timers;  
 * default time zone;  
 * listening event bus at the given scheduler address for the requests to.  
 
  
 -----------------
 
 ### <a name =\"requests-and-responses\"></a> Requests and responses.  
 
 _Chime_ communicates over event bus with `JsonObject` messages.
 Complete list of requests and responses is available
 at [Github](https://github.com/LisiLisenok/Chime/blob/master/howto.md).  
 
 Each request must contain `operation` field which identifies an action Chime has to perform.  
 The following operations are available:  
 * `create` - create new scheduler or timer.
 * `delete` - delete scheduler or timer.
 * `info` - request info on _Chime_ or on a particular scheduler or timer.
 * `state`:
 	* if set to `get` then scheduler or timer state has to be returned;
 	* if set to `running` then scheduler or timer is to be set to _running_ state;
 	* if set to `paused` then scheduler or timer is to be set to _paused_ state;
 
 
 -----------------
 
 ### <a name =\"scheduler\"></a> Scheduler.  
 
 At least one scheduler has to be created before creating timers.
 Each timer operates within some particular scheduler.  
 All messages _Chime_ listens are to be sent to _Chime_ address or to scheduler address.
 The difference is that _Chime address_ provides services for every scheduler, while
 messages to _scheduler address_ are only for this particular scheduler.  

 
 #### <a name =\"scheduler-request\"></a> Scheduler request.  
 
 In order to maintain schedulers send `JsonObject` message to _Chime_ address (specified in configuration, \"chime\" is default)
 in the following format:
 		JsonObject {
 			// operation code, mandatory
 			\"operation\" -> String,
 			// scheduler name, mandatory
 			\"name\" -> String|JsonArray,
 			// state, mandatory only if operation = 'state' otherwise optional
 			\"state\" -> String,
 			
 			// default time zone provider which applied to extract time zone, optional
 			\"time zone provider\" -> String,
 			// default time zone ID, overriden by timer time zone, optional
 			\"time zone\" -> String,
 			
 			// default message source type, optional
 			\"message source\" -> String,
 			// message source configuration passed to message source factory, optional
 			\"message source configuration\" -> JsonObject,
 			
 			// default event producer type, optional  
 			\"event producer\" -> String,
 			// default options applied to event producer factory
 			\"eventProducerOptions\" -> JsonObject
 		};
 
 > _Chime_ listens event bus at **scheduler name** address with messages for the given scheduler.  
 
 > Complete list of messages is available at [Github](https://github.com/LisiLisenok/Chime/blob/master/howto.md).  
 
 > `delivery options` field specifies event bus delivery options a timer fire event is to be sent with,
   see details in [timer.](#timer-request). Scheduler may contain default options, which used if no one given at timer level.  
 
 There are two limitations for the scheduler name:  
 1. Scheduler name must not be equal to _Chime_ address. Since both addresses are registered at event bus.  
 2. Scheduler name must not contain **:**. Since it is used as separator
    in full timer name - **scheduler name:timer name**, see [timer.](#timer).  
 
 > [[Scheduler]] interface provides a convenient way to eachange messages with particular scheduler.  
 
 
 #### <a name =\"scheduler-example\"></a> Scheduler example.  
 
 		// create scheduler with name 'scheduler'
 		eventBus.send<JsonObject> (
 			\"chime\",
 			JsonObject {
 				\"operation\" -> \"create\",
 				\"name\" -> \"scheduler\"
 			},
 			(Throwable|Message<JsonObject> msg) {
 				if (is Message<JsonObject> msg) {
 					// scheduler has been successfully created
 				}
 				else {
 					// error while creating scheduler
 				}
 			}
 		);
 		
 		// set scheduler state to paused
 		eventBus.send<JsonObject> (
 			\"chime\",
 			JsonObject {
 				\"operation\" -> \"state\",
 				\"name\" -> \"scheduler\",
 				\"state\" -> \"paused\"
 			},
 			(Throwable|Message<JsonObject> msg) {
 				if (is Message<JsonObject> msg) {
 					// scheduler state is set to paused
 				}
 				else {
 					// error while setting scheduler state
 				}
 			}
 		);
 
 
 -----------------
 
 ### <a name =\"timer\"></a> Timer.
 
 Once scheduler is created timers can be run within.  
 
 There are two ways to access a given timer:  
 * sending message to **scheduler name** address using timer short name **timer name**  
 * sending message to _Chime_ address using full timer name which is **scheduler name:timer name**  
 
 > Timer full name is _scheduler name_ and _timer name_ separated with ':', i.e. **scheduler name:timer name**.  
 
 > Timer fire message is sent to _timer full name_ address.  
 
 > Both scheduler and timer names must not contain **:**,
   since it is used as separator of **scheduler name:timer name**.  
 
 
 #### <a name =\"timer-request\"></a> Request.
 
 > Complete list of requests and responses is available
   at [Github](https://github.com/LisiLisenok/Chime/blob/master/howto.md).  
  
 Request has to be sent in `JsonObject` format to **scheduler name** address with _timer short name_
 or to **Chime** address with _timer full name_.  
 
 Request format:  
 	JsonObject {  
 		// operation code, mandatory
 		\"operation\" -> String,
 		// timer short or full name, mandatory  
 		\"name\" -> String|JsonArray,
 		// state, optional, except if operation = 'state' 
 		\"state\" -> String,
 		
 		// fields for create operation:
 		
 		// maximum number of fires, default - unlimited
 		\"maximum count\" -> Integer,
 		// if true message to be published and to be sent otherwise, optional, default is false
 		\"publish\" -> Boolean,
 
 		// start time, optional, if doesn't exist timer will start immediately
 		\"start time\" -> JsonObject  
 		{
 			// seconds, mandatory
 			\"seconds\" -> Integer,  
 			// minutes, mandatory
 			\"minutes\" -> Integer,  
 			// hours, mandatory
 			\"hours\" -> Integer,  
 			// days of month, mandatory
 			\"day of month\" -> Integer,  
 			// months, mandatory
 			\"month\" -> Integer|String,  
 			// year, mandatory
 			\"year\" -> Integer  
 		},
 
 		// end time, nonmadatory, default no end time
 		\"end time\" -> JsonObject  
 		{  
 			// seconds, mandatory
 			\"seconds\" -> Integer,  
 			// minutes, mandatory
 			\"minutes\" -> Integer,  
 			// hours, mandatory
 			\"hours\" -> Integer,  
 			// days of month, mandatory
 			\"day of month\" -> Integer,  
 			// months, mandatory
 			\"month\" -> Integer|String,  
 			// year, mandatory
 			\"year\" -> Integer  
 		},
 
		// time zone provider which applied to extract time zone, optional
		// default is jvm
		\"time zone provider\" -> String,
 		// time zone, optional, default is scheduler time zone
 		// or server local if not given at both scheduler and timer
 		\"time zone\" -> String,   

 		// message which passed to message source
 		// in order to extract final message to be attached to fire event
 		// optional
 		\"message\" -> JsonValue
 		// message source type, optional, default is direct
 		\"message source\" -> String,
 		// message source configuration passed to message source factory, optional
 		\"message source configuration\" -> JsonValue,

 		// event producer type, optional  
 		// default is one given at scheduler or event bus producer
 		\"event producer\" -> String,
 		// options applied to event producer factory
 		// default is given at scheduler or empty options
 		\"eventProducerOptions\" -> JsonObject
 
 		// timer desciption, mandatoty for create operation
 		\"description\" -> JsonObject  
 	};  
 
 Notes: 
 * `message` field is to be attached to [timer fire event](#timer-events).  
 * _Chime_ address could be specified in verticle configuration, default is \"chime\".  
 * If `create` request is sent to Chime address with full timer name and corresponding scheduler
   hasn't been created before then Chime creates both new scheduler and new timer.  
 * Timer fires only if both timer and scheduler states are _running_.  
 * `description` field is discussed [below](#supported-timers).  
 
 > [[Timer]] interface provides a convenient way to eachange messages with particular timer.  
 
 
 #### <a name =\"unique-timer-name\"></a> Unique timer name.  
 
 The _Chime_ may generate unique timer name automatically. Just follow next steps:  
 1. Set `operation` field to `create`.  
 2. Set `name` field to scheduler name (i.e. omit timer name).  
 3. Fill `description` field with required timer data.  
 4. Send message to _Chime_ or scheduler address.  
 5. Take the unique timer name from the response.  
 
 > `name` field can be empty or omitted at all if message is sent to scheduler address.  
 
 
 #### <a name =\"supported-timers\"></a> Supported timers.
 
 Timer is specified within _description_ field of timer create request.  

 
 * __Cron style timer__ is defined with cron-style:  
 		JsonObject {
 			// timer type, mandatory
 			\"type\" -> \"cron\",
 			// seconds in cron style, mandatory, nonempty
 			\"seconds\" -> String,
 			// minutes in cron style, mandatory, nonempty  
 			\"minutes\" -> String,
 			// hours in cron style, mandatory, nonempty  
 			\"hours\" -> String,
 			// days of month in cron style, mandatory, nonempty
 			\"days of month\" -> String,
 			// months in cron style, mandatory, nonempty  
 			\"months\" -> String,
 			// days of week in cron style, L means last, # means nth of month, optional
 			\"days of week\" -> String,
 			// year in cron style, optional
 			\"years\" -> String
 		};  
 
 Details of cron specification is listed [below](#cron-expression).  
 
 > Month and day of week may be specified either with digits or names.
 > Names are case insensitive and might be either short or full.  
 > Sunday is the first day of week.  
 
 > [[CronBuilder]] may help to build `JsonObject` description of a cron timer.  
 
 ------------------------------------------  
   
 * __Interval timer__ fires after each given time period (minimum 1 second):  
 		JsonObject {
 			// timer type, mandatory
 			\"type\" -> \"interval\",
 			// timer delay in seconds, must be > 0, mandatory
 			\"delay\" -> Integer
 		};  
 
 > Interval timer delay is in _seconds_
 
 ------------------------------------------  
   
 * __Union timer__ combines a number of timers into a one:  
 		JsonObject {  
 			// timer type, mandatory
 			\"type\" -> \"union\",
 			// list of the timers, each item is JSON according to its description, mandatory
 			\"timers\" -> JsonArray
 		};  
 
 This may be useful to fire at specific dates / times. For example, following timer fires
 at 8-00 each Monday and at 17-00 each Friday:  
 		JsonObject {  
 			\"type\" -> \"union\",  
 			\"timers\" -> JsonArray {
 				JsonObject {
 					\"type\" -> \"cron\",
 					\"seconds\" -> \"0\",  
 					\"minutes\" -> \"0\",  
 					\"hours\" -> \"8\",  
 					\"days of month\" -> \"*\",  
 					\"months\" -> \"*\",  
 					\"days of week\" -> \"Monday\"
 				},
 				JsonObject {
 					\"type\" -> \"cron\",
 					\"seconds\" -> \"0\",  
 					\"minutes\" -> \"0\",  
 					\"hours\" -> \"17\",  
 					\"days of month\" -> \"*\",  
 					\"months\" -> \"*\",  
 					\"days of week\" -> \"Friday\" 
 				}  
  			}  
 		};  
 
 > [[UnionBuilder]] may help to build `JsonObject` description of a union timer.  
 
 ------------------------------------------
 
 * __Custom timer__  
   Custom timer may be instantiated using service provider. See details in [[package herd.schedule.chime.service]].  
 

 #### <a name =\"timer-events\"></a> Events
 
 Timer sends or publishes to _full timer name_ address ('scheduler name:timer name') two types of events in `JSON`:
 * fire event  
 		JsonObject {
 			// timer name
 			\"name\" -> String,
 			// event type
 			\"event\" -> \"fire\",  
 			// total number of fire times
 			\"count\" -> Integer,
 			// string formated time / date
 			\"time\" -> String,
 			// number of seconds since last minute
 			\"seconds\" -> Integer,
 			// number of minutes since last hour
 			\"minutes\" -> Integer,
 			// hour of day
 			\"hours\" -> Integer,
 			// day of month
 			\"day of month\" -> Integer,
 			// month
 			\"month\" -> Integer,
 			// year
 			\"year\" -> Integer,
 			// time zone the timer works in
 			\"time zone\" -> String,
 			// message provided by message source
 			\"message\" -> JsonValue
 		};  
 * complete event  
 		JsonObject {  
 			// timer name
 			\"name\" -> String,
 			// event type
 			\"event\" -> \"complete\",
 			// total number of fire times
 			\"count\" -> Integer  
 		};  
 
 
 > Fire event is sent or published with delivery options given at [timer create request](#timer-request).  
 
 > Complete event is always published in order every listener receives it.  
   While fire event may be either published or send depending on 'publish' field in timer create request.  
 
 > The value at the 'event' key indicates the event type (fire or complete).  
 
 > _Timer full name_ is _scheduler name_ and _timer name_ separated with ':', i.e. \"scheduler name:timer name\".  
 
 > String formatted time / date is per [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601).  
 
 
 #### <a name =\"time-zones\"></a> Time zones.
 
 [Available time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones),
 actual availability may depend on particular JVM installation.  
 
 See also [time zones and JRE](http://www.oracle.com/technetwork/java/javase/dst-faq-138158.html).
 
 Time zone may be set at either scheduler or timer level.
 If no time zone is set at timer then scheduler time zone is applied
 otherwise timer timezone is used. If no timezone is given at all
 then time zone local for the machine is used.  
 
 By default, time zones are extracted from JVM. This may be overriden by creating a custom time zone provider.
 See details in [[package herd.schedule.chime.service]].   
 
 
 #### <a name =\"timer-message-source\"></a> Message source.  
 
 Message attached to the timerfire event may be extracted from some source.
 The source is provided by service provider. See details in [[package herd.schedule.chime.service]].  
 
 
 #### <a name =\"timer-example\"></a> Example.
 
 		// creat new Scheduler with name \"scheduler\" at first and then create timer
 		eventBus.send<JsonObject> (
 			\"chime\",
 			JsonObject {
 				\"operation\" -> \"create\",
 				\"name\" -> \"scheduler\"
 			},
 			(Throwable|Message<JsonObject> msg) {
 				if (is Message<JsonObject> msg) {
 					// create timer
 					eventBus.send<JsonObject>(
 						\"chime\",
 						JsonObject {
 							\"operation\" -> \"create\",
 							// full timer name == address to listen timer
 							\"name\" -> \"scheduler:timer\",
 							\"max count\" -> 3,
 							\"time zone\" -> \"Europe/Paris\",
 							\"descirption\" -> JsonObject {
 								// timer type is 'cron'
 								\"type\" -> \"cron\",
 								// 27 with step 30 leads to fire at 27 and 57 seconds
 								\"seconds\" -> \"27/30\",
 								// every minute
 								\"minutes\" -> \"*\",
 								// every hour
 								\"hours\" -> \"*\",
 								// every day
 								\"days of month\" -> \"*\",
 								// from January and up to October
 								\"months\" -> \"january-OCTOBER\",
 								// at second Saturday and at each Sunday
 								\"days of week\" -> \"sat#2,sunday\", 
 								\"years\" -> \"2015-2019\"
 							}
 						},
 						(Throwable|Message<JsonObject?> msg) {
 							// Chime replies if timer successfully created or some error occured
 							print(msg);
 						}
 					);
 				}
 				else {
 					print(\"error while creating scheduler: \`\`msg\`\`\");
 				}
 			}
 		);
 		
 		// listen timer
 		eventBus.consumer (
 			\"scheduler:timer\",
 			(Throwable | Message<JsonObject?> msg) {
 				...
 			}
 		);
 
  
 ------------------------------------------  
 
 ### <a name =\"scheduler-timer-interfaces\"></a> Scheduler and Timer interfaces.  
 
 [[Scheduler]] interface provides a convenient way to exchange messages with particular scheduler.  
 In order to connect to already existed scheduler or to create new one [[connectScheduler]]
 function can be used. The function sends [create scheduler request.](#scheduler-request) to the _Chime_ and wraps
 the event bus with implementation of [[Scheduler]] interface.  
 
 [[Timer]] interface provides a convenient way to exchange messages with particular timer.  
 To get an instance of the [[Timer]] call [[Scheduler.createIntervalTimer]],
 [[Scheduler.createCronTimer]], [[Scheduler.createUnionTimer]] or [[Scheduler.createTimer]].  
 
 Example:
 
 		connectToScheduler (
 			(Throwable|Scheduler scheduler) {
 				if (is Scheduler scheduler) {
 					scheduler.createIntervalTimer (
 						(Throwable|Timer timer) {
 							if (is Timer timer) {
 								timer.handler (
 									(TimerEvent event) {...}
 								);
 							}
 							else {
 								// error while creating timer
 							}
 						},
 						5 // fires each 5 seconds
 					);
 				}
 				else {
 					// error while creating / connecting to scheduler
 				}
 			},
 			\"chime\", eventBus, \"scheduler name\"
 		);
 
  
 ------------------------------------------  
 
 ### <a name =\"error-messages\"></a> Error messages.  
 
 The error is sent using `Message.fail` with corresponding code and message.  
 See [[Chime.errors]] for the complete list of errors.  
 
  
 ------------------------------------------  
 
 ## <a name =\"cron-expression\"></a> Cron expression.  
 
 #### <a name =\"cron-expression-fields\"></a> Expression fields.  
 
 * _seconds_, mandatory  
 	* allowed values: 0-59  
 	* allowed special characters: , - * /  
 * _minutes_, mandatory  
 	* allowed values: 0-59  
 	* allowed special characters: , - * /  
 * _hours_, mandatory  
 	* allowed values: 0-23  
 	* allowed special characters: , - * /  
 * _days of month_, mandatory  
 	* allowed values 1-31  
 	* allowed special characters: , - * /  
 * _months_, mandatory  
 	* allowed values 1-12, Jan-Dec, January-December  
 	* allowed special characters: , - * /  
 * _days of week_, optional  
 	* allowed values 1-7, Sun-Sat, Sunday-Saturday  
 	* allowed special characters: , - * / L #  
 * _years_, optional  
 	* allowed values 1970-2099  
 	* allowed special characters: , - * /  
 
 Following notations are applicable:  
 * `FROM`-`TO`/`STEP`, for example, '0-30/15' means '0,15,30'  
 * `FROM`/`STEP`, in this case `TO` is set to maximum allowed for the given field,
   for example, '0/15' in seconds field means '0,15,30,45'  
 * `FROM`-`TO`, for example, '10-12' means '10, 11, 12'  
 * '*' means any allowed  
 * month can be specified using digits (1 is for January) or using names (like 'jan' or 'january', case insensitive)  
 * day of week can be specified using digits (1 is for Sunday) or using names (like 'sun' or 'sunday', case insensitive)  

 > Names of months and days of the week are case insensitive.  
 
 > Sunday is the first day of week.  

  
 #### <a name =\"cron-special-characters\"></a> Special characters.
 
 * '*' means all values  
 * ',' separates list items  
 * '-' specifies range, for example, '10-12' means '10, 11, 12'  
 * '/' specifies increments, for example, '0/15' in seconds field means '0,15,30,45',
   '0-30/15' means '0,15,30'  
 * 'L' has to be used after digit and means _the last xxx day of the month_,
   where xxx is day of week, for example, '6L' means _the last Friday of the month_  
 * '#' has to be used with digits before and after: 'x#y' and means _the y'th x day of the month_,
   for example, '6#3' means _the third Friday of the month_   
 
 
 #### <a name =\"cron-expression-builder\"></a> Cron expression builder.  
 
 [[CronBuilder]] may help to build `JsonObject` description of a cron timer.
 The builder has a number of function to add particular cron record to the description.
 The function may be called in any order and any number of times.  
 Finally, [[CronBuilder.build]] has to be called to build the timer `JsonObject` description.  
 
 Example:  
 		JsonObject cron = CronBuilder().withSeconds(3).withMinutes(0).withHours(1).withAllDays().withAllMonths().build();
 
 > Note that 'seconds', 'minutes', 'hours', 'days of month' and 'month' are required fields.
   While 'years' and 'days of week' are optional.  
 
 "
license (
	"The MIT License (MIT)
	 
	 Permission is hereby granted, free of charge, to any person obtaining a copy
	 of this software and associated documentation files (the \"Software\"), to deal
	 in the Software without restriction, including without limitation the rights
	 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	 copies of the Software, and to permit persons to whom the Software is
	 furnished to do so, subject to the following conditions:
	 
	 The above copyright notice and this permission notice shall be included in all
	 copies or substantial portions of the Software.
	 
	 THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	 SOFTWARE."
)
by("Lis")
native("jvm")
module herd.schedule.chime "0.3.0" {
	shared import io.vertx.ceylon.core "3.4.2";
	shared import ceylon.time "1.3.3";
	import ceylon.json "1.3.2";
}