# Complete list of json messages version 0.3.0.  

## Content.  
* [Terminology](#terminology)
* [Chime](#chime)
	* [configuration](#configuration)
	* [info on installed extensions](#info-on-installed-extensions)
* [Scheduler](#scheduler-request)  
	* [create scheduler](#create-scheduler)  
	* [delete scheduler](#delete-scheduler)  
	* [delete all schedulers](#delete-all-schedulers)  
	* [delete a list of schedulers](#delete-a-list-of-schedulers)  
	* [get scheduler info](#get-scheduler-info)  
	* [get info on all schedulers](#get-info-on-all-schedulers)  
	* [get info on a list of schedulers](#get-info-on-a-list-of-schedulers)  
	* [get scheduler state](#get-scheduler-state)  
	* [set scheduler to paused state](#set-scheduler-to-paused-state)  
	* [set scheduler to running state](#set-scheduler-to-running-state)  
* [Timer](#timer-request)  
	* [create timer](#create-timer)  
	* [delete timer](#delete-timer)  
	* [delete a list of timers](#delete-a-list-of-timers)  
	* [get timer info](#get-timer-info)  
	* [get info on a list of timers](#get-info-on-a-list-of-timers)  
	* [get timer state](#get-timer-state)  
	* [set timer to paused state](#set-timer-to-paused-state)  
	* [set timer to running state](#set-timer-to-running-state)  
* [Timer descriptions](#timer-descriptions)  
	* [cron-style timer](#cron-style-timer)  
	* [interval timer](#interval-timer)  
	* [union timer](#union-timer)  
* [Timer events](#timer-events)  
	* [fire event](#fire-event)  
	* [complete event](#complete-event)  

-------------

## Terminology.  

* _Chime_ address is event bus address _Chime_ is listen to.
  Given with verticle configuration. Default is "chime".  
* Scheduler address or name is given name scheduler is created with.
  _Chime_ listens event bus at this address for the messages to the given scheduler.  
* Timer name is given name timer is created with.  
* Timer full name is 'scheduler name' and 'timer name' separated with ':', i.e. 'scheduler name:timer name'.
  _Chime_ sends or publishes timer events to this address.  

-------------

## Chime.

### Configuration.

Provided with verticle deploy configuration.  
```json
{
	"address": "String address Chime has to listen, default is 'chime'",
	"tolerance": "Integer tolerance in milliseconds used to compare actual and requested times, default is 10ms",
	"local": "Boolean, If 'true' _Chime_ and schedulers event bus addresses have not to propagate across the cluster",
	"services": [
		"module name/module version"
	],
	"schedulers": ["list of schedulers as JsonObjects"],
	"timers": ["list of timers as JsonObjects"],
}
```  

`services` is a list of modules with version to look the extensions as service providers.  

`local` identifies the event bus listening area.  
If `true` _Chime_ and schedulers event bus addresses have not to propagate across the cluster,
i.e. _Chime_ has to listen only messages from this local node.  
If `false` _Chime_ has to listen all nodes in the cluster.  
Default is `false`.  

`schedulers` is a list of schedulers to be instantiated at start.
Each scheduler is in format as described in [create scheduler](#create-scheduler) section.  

`timers` is a list of timers to be instantiated at start.
Each timer is in format as described in [create timer](#create-timer).  

Additional options may be specified to be available to extensions during initialization.  


### Info on installed extensions.

To be sent to _Chime_ address.  

##### Request.  
```json
{
	"operation": "info",
	"name": ""
}
```  

##### Response.
```json
{
	"schedulers": [],
	"services": [
		{
			"type": "parameter declaration",
			"provider type, returned by 'Extension.type'": "declaration"
		}
	]
}
```  
Where `schedulers` array contains `JsonObject`'s of [scheduler info](#get-scheduler-info).

-------------

## Scheduler request.  

### Create scheduler.  

To be sent to _Chime_ address.  

##### Request.
```json
{
	"operation": "create",
	"name": "scheduler name",
	"state": "String, optional, one of running, paused or completed, default is running",
	"time zone": "String, optional, default time zone, applied to timer if no one given at timer level",
	"time zone provider": "String, optional, extracts default time zone",
	"message source": "String, optional, default message source",
	"message source options": "JsonObject, optional, options applied to instantiate message source",
	"event producer": "String, optional, default event producer type",
	"event producer options": "JsonObject, optional, default options applied to event producer factory"
}
```  

`operation` and `name` fields are mandatory.  

`state` field is optional with default value set to "running".  

`time zone` field is optional. Time zone applied at scheduler level is default for timers [created](#create-timer) within this scheduler. If `time zone provider` then the given provider is used to extract time zone, otherwise default "jvm" provider is used.  
[Available time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).  

##### Response.
```json
{
	"name": "scheduler name",
	"state": "running, paused or completed"
}
```  

-------------

### Delete scheduler.  

To be sent to _Chime_ address or to _scheduler_ address.  

##### Request.  
```json
{
	"operation": "delete",
	"name": "scheduler name"
}
```

##### Response.
```json
{
	"name": "scheduler name",
	"state": "completed"
}
```  

-------------

### Delete all schedulers.  

To be sent to _Chime_ address.  

##### Request.  
```json
{
	"operation": "delete",
	"name": ""
}
```

##### Response.
```json
{
	"schedulers": ["name of first scheduler name", "...", "name of nth scheduler"]
}
```  
Where 'schedulers' array contains `String` names of deleted schedulers.  

-------------

### Delete a list of schedulers.  

To be sent to _Chime_ address.  

##### Request.  
```json
{
	"operation": "delete",
	"name": ["name of first scheduler", "...", "name of nth scheduler"]
}
```
Where name array contains `String`s with names of schedulers to be deleted.  

##### Response.
```json
{
	"schedulers": ["name of first scheduler", "...", "name of nth scheduler"]
}
```  
Where 'schedulers' array contains `String` names of actually deleted schedulers.  

-------------

### Get scheduler info.  

To be sent to _Chime_ address or to _scheduler_ address.  

##### Request.  
```json
{
	"operation": "info",
	"name": "scheduler name"
}
```  

##### Response.
```json
{
	"name": "scheduler name",
	"state": "running, paused or completed",
	"time zone": "time zone ID",
	"timers": []
}
```  
Where `timers` array contains `JsonObject`'s of [timer info](#get-timer-info).

-------------

### Get info on all schedulers.  

see [info on installed extensions](#info-on-installed-extensions)

-------------

### Get info on a list of schedulers.  

To be sent to _Chime_ address.  

##### Request.  
```json
{
	"operation": "info",
	"name": ["name of first scheduler", "...", "name of nth scheduler"]
}
```  
Where `names` is array of `Strings` with names of schedulers info is requested for.  

##### Response.
```json
{
	"schedulers": []
}
```  
Where `schedulers` array contains `JsonObject`'s of [scheduler info](#get-scheduler-info).  

-------------

### Get scheduler state.  

To be sent to _Chime_ address or to _scheduler_ address.  

##### Request.  
```json
{
	"operation": "state",
	"name": "scheduler name",
	"state": "get"
}
```  

##### Response.
```json
{
	"name": "scheduler name",
	"state": "String, one of running, paused or completed"
}
```  

-------------

### Set scheduler to paused state.  

To be sent to _Chime_ address or to _scheduler_ address.  
Pausing scheduler leads to all timers operated within the given scheduler are paused.  

##### Request.  
```json
{
	"operation": "state",
	"name": "scheduler name",
	"state": "paused"
}
```

##### Response.
```json
{
	"name": "scheduler name",
	"state": "paused"
}
```  

-------------

### Set scheduler to running state.  

To be sent to _Chime_ address or to _scheduler_ address.  
Resuming scheduler leads to all timers with running state are resumed.
While timers with paused state are remain paused.  

##### Request.  
```json
{
	"operation": "state",
	"name": "scheduler name",
	"state": "running"
}
```

##### Response.
```json
{
	"name": "scheduler name",
	"state": "running"
}
```  

-------------


## Timer request.  

### Create timer.  

To be sent to _Chime_ address with full timer name, i.e. "scheduler name:timer name"
or to _scheduler_ address with either full or short timer name.  

##### Request.  
```json
{
	"operation": "create",
	"name": "scheduler name:timer name",
	"description": {},
	"state": "String, one of running, paused or completed, default is running",
	"maximum count": "Integer, maximum number of fires, default is unlimited",
	"start time": {
 		"seconds": "Integer",
 		"minutes": "Integer",
 		"hours": "Integer",
 		"day of month": "Integer",
 		"month": "Integer or String",
 		"year": "Integer"
	},
	"end time": {
 		"seconds": "Integer",
 		"minutes": "Integer",
 		"hours": "Integer",
 		"day of month": "Integer",
 		"month": "Integer or String",
 		"year": "Integer"
	},
	"time zone": "String, default is local time zone",
	"time zone provider": "String, extracts time zone, default is jvm",
	"message": "any Json value",
	"message source": "String, source type applied to extract message, default is given at scheduler or empty",
	"message source options": "String, options to instantiate message source",
	"event producer": "String, optional, event producer type",
	"event producer options": "JsonObject, optional, options applied to event producer factory"	
}
```  
Where `operation`, `name`, and `description` are mandatory fields.  
`description` field contains `JsonObject` with [timer descriptions](#timer-descriptions).  
Other fields are optional, default values are:  
* `state` = "running"  
* `maximum count` = unlimited    
* `start time` = right now  
* `end time` = never  
* `time zone` = given at scheduler level or local  
* `time zone provider` = used only if `time zone` is given, default is "jvm"
* `message` = unused  
* `message source` = given at scheduler level or unused  
* `message source options` = used only if `message source` is given  
* `event producer` = given at scheduler level or event bus  
* `event producer options` = given at scheduler level or empty  

> If name field is empty then unique timer name is generated,
  created timer is attached to default scheduler and timer full name
  (i.e. address to listen timer fire events) is returned with response in `name` field.  

> If only scheduler name is given in name field (i.e. timer name is omitted) then
  unique timer name is generated, created timer is attached to the given scheduler
  and timer full name (i.e. address to listen timer fire events) is returned with response
  in `name` field.  

> If scheduler with 'scheduler name' hasn't been [created](#create-scheduler) before 
  then new scheduler with 'scheduler name' will be created.  

> [Available time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).  

#### Response.  
```json
{
	"name": "scheduler name:timer name",
	"state": "running, paused or completed"
}
```  

-------------

### Delete timer.  

To be sent to _Chime_ address with full timer name, i.e. "scheduler name:timer name"
or to _scheduler_ address with either full or short timer name.  

##### Request.  
```json
{
	"operation": "delete",
	"name": "scheduler name:timer name"
}
```

##### Response.
```json
{
	"name": "scheduler name:timer name",
	"state": "completed"
}
```  

-------------

### Delete a list of timers.  

To be sent to _Chime_ address with full timer name, i.e. "scheduler name:timer name"
or to _scheduler_ address with either full or short timer name.  

##### Request.  
```json
{
	"operation": "delete",
	"name": ["scheduler name:timer name"]
}
```
Where 'name' array contains `String`s with names of timers to be deleted.  

##### Response.
```json
{
	"timers": ["name of first timer", "..." "name of nth timer"]
}
```  
Where 'timers' array contains `String`s with names of actually deleted timers.

-------------

### Get timer info.  

To be sent to _Chime_ address with full timer name, i.e. "scheduler name:timer name"
or to _scheduler_ address with either full or short timer name.  

##### Request.  
```json
{
	"operation": "info",
	"name": "scheduler name:timer name"
}
```  

##### Response.
```json
{
	"name": "scheduler name:timer name",
	"state": "running, paused or completed",
	"count": "Integer, total number of fires when request is received",
	"max count": "Integer, maximum allowed number of fires",
	"start time": {
		"seconds": "Integer",
		"minutes": "Integer",
		"hours": "Integer",
		"dayOfMonth": "Integer",
		"month": "String",
		"year": "Integer"
	},
	"end time": {
		"seconds": "Integer",
		"minutes": "Integer",
		"hours": "Integer",
		"dayOfMonth": "Integer",
		"month": "String",
		"year": "Integer"
	},
	"time zone": "String, time zone the timer operates with",
	"description": {}
}
```  
Response contains all fields set at [timer create request](#create-timer).  
`description` field contains `JsonObject` with [timer descriptions](#timer-descriptions).  

`start time`, `end time` and `max count` are optional and may not be given if ignored in timer create request.  

-------------

### Get info on a list of timers.  

To be sent to _Chime_ address with full timer name, i.e. "scheduler name:timer name"
or to _scheduler_ address with either full or short timer name.  

##### Request.  
```json
{
	"operation": "info",
	"name": ["name of first timer", "..." "name of nth timer"]
}
```  
Where `names` is array of `Strings` with names of timers the info is requested for.  

##### Response.
```json
{
	"timers": []
}
```  
Where `timers` array contains `JsonObject`'s of [timer info](#get-timer-info).  

-------------

### Get timer state.  

To be sent to _Chime_ address with full timer name, i.e. "scheduler name:timer name"
or to _scheduler_ address with either full or short timer name.  

##### Request.  
```json
{
	"operation": "state",
	"name": "scheduler name:timer name",
	"state": "get"
}
```

##### Response.
```json
{
	"name": "scheduler name:timer name",
	"state": "running, paused or completed"
}
```  

-------------

### Set timer to running state.  

To be sent to _Chime_ address with full timer name, i.e. "scheduler name:timer name"
or to _scheduler_ address with either full or short timer name.  

##### Request.  
```json
{
	"operation": "state",
	"name": "scheduler name:timer name",
	"state": "running"
}
```

##### Response.
```json
{
	"name": "scheduler name:timer name",
	"state": "running"
}
```  

-------------

### Set timer to paused state.  

To be sent to _Chime_ address with full timer name, i.e. "scheduler name:timer name"
or to _scheduler_ address with either full or short timer name.  

##### Request.  
```json
{
	"operation": "state",
	"name": "scheduler name:timer name",
	"state": "paused"
}
```  

##### Response.
```json
{
	"name": "scheduler name:timer name",
	"state": "paused"
}
```  

-------------


## Timer descriptions.  

Used in [timer create request](#create-timer).  

### Cron-style timer.  
```json
{
	"type": "cron",
	"seconds": "String in cron-style",
	"minutes": "String in cron-style",
	"hours": "String in cron-style",
	"days of month": "String in cron-style",
	"months": "String in cron-style",
	"days of week": "String in cron-style, optional",
	"years": "String in cron-style, optional"
}
```  
`type`, `seconds`, `minutes`, `hours`, `days of month` and `months` are mandatory.  
`days of week` and `years` are optional.  

##### Cron specification.  

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
 
> Names of months and days of the week are case insensitive.  
 
> Sunday is the first day of week.  
 
##### Special characters.  

* '*' means all values  
* ',' separates list items  
* '-' specifies range, for example, '10-12' means '10, 11, 12'  
* '/' specifies increments, for example, '0/15' in seconds field means '0,15,30,45',
  '0-30/15' means '0,15,30'  
* 'L' has to be used after digit and means _the last xxx day of the month_,
  where xxx is day of week, for example, '6L' means _the last Friday of the month_  
* '#' has to be used with digits before and after: 'x#y' and means _the y'th x day of the month_,
  for example, '6#3' means _the third Friday of the month_  

-------------

### Interval timer.  
```json
{
	"type": "interval",
	"delay": "Integer > 0"
}
```  
`type` and `interval` are mandatory.  

-------------

### Union timer.  
```json
{
	"type": "union",
	"timers": []
}
```  
Where `timers` array contains `JsonObject`'s of [timer descriptions](#timer-descriptions).  
`type` and `timers` are mandatory.   

-------------


## Timer events.  


### Fire event.  

Sent or published by _Chime_ to timer full name ("scheduler name:timer name") address.  

```json
{  
	"name": "String, timer name",  
	"event": "fire",
	"count": "Integer, total number of fire times",
	"time": "String formated time / date",
	"seconds": "Integer, number of seconds since last minute",
	"minutes": "Integer, number of minutes since last hour",
	"hours": "Integer, hour of day",
	"day of month": "Integer, day of month",
	"month": "Integer, month",
	"year": "Integer, year",
	"time zone": "String, time zone the timer works in",
	"message": "message given at a timer create request, optional"  
}
```  
`message` is given at [create timer request](#create-timer) in any Json supported type.  

-------------

### Complete event.  

Published by _Chime_ to timer full name ("scheduler name:timer name") address.  

```json
{
	"name": "scheduler name:timer name",
	"event": "complete",
	"count": "Integer, total number of fires"
}
```  

> Complete event is always published in order all consumers may receive it.  
