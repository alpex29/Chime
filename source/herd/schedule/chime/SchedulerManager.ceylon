import io.vertx.ceylon.core {

	Vertx
}
import io.vertx.ceylon.core.eventbus {

	Message
}
import ceylon.json {
	
	JSON=Object,
	JSONArray=Array
}
import ceylon.collection {

	HashMap
}
import herd.schedule.chime.timer {
	TimeRowFactory
}


"manages shcedulers - [[TimeScheduler]]:
 * creates
 * deletes
 * starts
 * pauses
 * schedulers info
 
 Instances of the class are used internaly by Chime.  
 All operations performed as response on request send to general Chime address, \"chime\" by default.
 Or specified in configuration file.
 Scheduler to be created before any operations with timers requested.
 
 ### Requesting:  
 
 expects messages in `JSON` format:  
 	{  
 		\"operation\" -> String // operation code, mandatory  
 		\"name\" -> String // scheduler or full timer (\"scheduler name:timer name\") name, mandatory   
 		\"state\" -> String // state, mandatory only for state operation   
 	} 
 
 If timer name specified as *\"scheduler name:timer name\"* operation is performed for timer - 
 see description in [[TimeScheduler]] otherwise for scheduler - see description below.
 
 #### operation codes: 
 * \"create\" - create new scheduler with specified name, state and description, if state is not specified, sceduler to be run.
   If full timer name specified *`scheduler name`:`timer name`* timer is to be created, if no scheduler with \"scheduler name\"
   has been created before, it will be created.
 * \"delete\" - delete scheduler with name `name` (or timer if full timer name specified *\"scheduler name:timer name\"*)
 * \"info\" - requesting info on Chime, specific scheduler (scheduler name to be provided) or
 timer (full timer name specified *\"scheduler name:timer name\"* to be provided)
 * \"state\":
 	* if is \"get\" state is to be returned
 	* if is \"running\" scheduler is to be run if not already
 	* if is \"paused\" scheduler is to be paused if not already
 	* otherwise error is returned

 #### examples:
 	// create new scheduler with name \"scheduler name\"
 	JSON message = JSON { 
 		\"operation\" -> \"create\", 
 		\"name\" -> \"scheduler name\" 
 	} 
  	
  	// change state of scheduler with \"scheduler name\" on paused
 	JSON message = JSON { 
 		\"operation\" -> \"state\", 
 		\"name\" -> \"scheduler name\",  
 		\"state\" -> \"paused\"
 	} 
 	
 ### Response  
 response on messages is in `JSON`:  
 	{  
 		\"name\" -> String // scheduler or full timer (\"scheduler name:timer name\") name  
 		\"state\" -> String // scheduler state  
 		\"schedulers\" -> JSONArray // scheduler names, exists as response on \"info\" operation with no \"name\" field  
 	}
 	
 or fail message with corresponding error, see [[Chime.errors]].  

 "
since( "0.1.0" ) by( "Lis" )
see(`class TimeScheduler`)
class SchedulerManager(
	"Address the _Cime_ listens to." String address,
	"Vetrx the scheduler is running on." Vertx vertx,
	"Factory to create timers" TimeRowFactory factory,
	"Factory to instantiates time converters." TimeConverterFactory converterFactory,
	"Tolerance to compare fire time and current time in miliseconds." Integer tolerance 
)
		extends Operator( address, vertx.eventBus() )
{
	
	"Time schedulers."
	HashMap<String, TimeScheduler> schedulers = HashMap<String, TimeScheduler>();
	
	TimerCreator creator = TimerCreator( factory, converterFactory );

	
	"Adds new scheduler.  
	 Retruns new or already existed shceduler with name `name`."
	TimeScheduler addScheduler (
		"Scheduler name." String name,
		"Scheduler state." State state,
		"Default converter applied if no time zone given." TimeConverter defaultConverter
	) {
		if ( exists sch = schedulers.get( name ) ) {
			return sch;
		}
		else {
			TimeScheduler sch = TimeScheduler( name, schedulers.remove, vertx, creator, tolerance, defaultConverter );
			schedulers.put( name, sch );
			sch.connect();
			if ( state == State.running ) {
				sch.start();
			}
			return sch;
		}
	}

	
// operation methods
	
	"Creates operators map"
	shared actual Map<String, Anything(Message<JSON?>)> createOperators()
			=> map<String, Anything(Message<JSON?>)> {
				Chime.operation.create -> operationCreate,
				Chime.operation.delete -> operationDelete,
				Chime.operation.state -> operationState,
				Chime.operation.info -> operationInfo
			};
	
	"Processes 'create new scheduler' operation."
	void operationCreate( Message<JSON?> msg ) {
		if ( exists request = msg.body(), is String name = request[Chime.key.name], !name.empty && name != address ) {
			String schedulerName;
			String timerName;
			if ( exists inc = name.firstInclusion( Chime.configuration.nameSeparator ) ) {
				schedulerName = name.spanTo( inc - 1 );
				timerName = name;
			}
			else {
				schedulerName = name;
				timerName = "";
			}
			// instantiate scheduler
			if ( exists converter = converterFromRequest( request, converterFactory, emptyConverter ) ) {
				value scheduler = addScheduler( schedulerName, extractState( request ) else State.running, converter );
				if ( request.defines( Chime.key.description ) ) {
					// add timer to scheduler
					scheduler.operationCreate( msg );
				}
				else {
					// timer description is not specified - reply with info on scheduler
					msg.reply( scheduler.shortInfo );
				}
			}
			else {
				// incorrect time zone
				msg.fail( Chime.errors.codeUnsupportedTimezone, Chime.errors.unsupportedTimezone );
			}
		}
		else {
			// response with wrong format error
			msg.fail( Chime.errors.codeSchedulerNameHasToBeSpecified, Chime.errors.schedulerNameHasToBeSpecified );
		}
	}
	
	"Processes 'delete scheduler' operation."
	void operationDelete( Message<JSON?> msg ) {
		if ( exists request = msg.body(), is String name = request[Chime.key.name] ) {
			if ( name.empty || name == address ) {
				// remove all schedulers
				for ( scheduler in schedulers.items ) {
					scheduler.stop();
				}
				schedulers.clear();
				msg.reply (
					JSON {
						Chime.key.schedulers -> JSONArray( [ for ( scheduler in schedulers.items ) scheduler.fullInfo ] )
					}
				);
			}
			else if ( exists sch = schedulers.remove( name ) ) {
				// delete scheduler
				sch.stop();
				// scheduler successfully removed
				msg.reply( sch.shortInfo );
			}
			else {
				// scheduler doesn't exists - look if name is full timer name
				value schedulerName = name.spanTo( ( name.firstInclusion( Chime.configuration.nameSeparator ) else 0 ) - 1 );
				if ( !schedulerName.empty, exists sch = schedulers[schedulerName] ) {
					// scheduler has to remove timer
					sch.operationDelete( msg );
				}
				else {
					// scheduler or timer doesn't exist
					msg.fail( Chime.errors.codeSchedulerNotExists, Chime.errors.schedulerNotExists );
				}
			}
		}
		else {
			// response with wrong format error
			msg.fail( Chime.errors.codeSchedulerNameHasToBeSpecified, Chime.errors.schedulerNameHasToBeSpecified );
		}
	}
	
	"Processes 'scheduler state' operation."
	void operationState( Message<JSON?> msg ) {
		if ( exists request = msg.body(), is String name = request[Chime.key.name] ) {
			if ( is String state = request[Chime.key.state] ) {
				if ( exists sch = schedulers[name] ) {
					sch.replyWithSchedulerState( state, msg );
				}
				else {
					// scheduler doesn't exists - look if name is full timer name
					value schedulerName = name.spanTo( ( name.firstInclusion( Chime.configuration.nameSeparator ) else 0 ) - 1 );
					if ( !schedulerName.empty, exists sch = schedulers[schedulerName] ) {
						// scheduler has to provide timer state
						sch.operationState( msg );
					}
					else {
						// scheduler or timer doesn't exist
						msg.fail( Chime.errors.codeSchedulerNotExists, Chime.errors.schedulerNotExists );
					}
				}
			}
			else {
				// scheduler state to be specified
				msg.fail( Chime.errors.codeStateToBeSpecified, Chime.errors.stateToBeSpecified );
			}
		}
		else {
			// scheduler name to be specified
			msg.fail( Chime.errors.codeSchedulerNameHasToBeSpecified, Chime.errors.schedulerNameHasToBeSpecified );
		}
	}
	
	"Replies with Chime or particular scheduler or timer info."
	void operationInfo( Message<JSON?> msg ) {
		value nn = msg.body()?.get( Chime.key.name );
		if ( is String name = nn, !name.empty, name != address ) {
			if ( exists sch = schedulers[name] ) {
				// reply with scheduler info
				msg.reply( sch.fullInfo );
			}
			else {
				// scheduler doesn't exists - look if name is full timer name
				value schedulerName = name.spanTo( ( name.firstInclusion( Chime.configuration.nameSeparator ) else 0 ) - 1 );
				if ( !schedulerName.empty, exists sch = schedulers[schedulerName] ) {
					// scheduler has to reply for timer info
					sch.operationInfo( msg );
				}
				else {
					// scheduler or timer doesn't exist
					msg.fail( Chime.errors.codeSchedulerNotExists, Chime.errors.schedulerNotExists );
				}
			}
		}
		else if ( is JSONArray arr = nn, nonempty names = arr.narrow<String>().sequence() ) {
			msg.reply (
				JSON {
					Chime.key.schedulers -> JSONArray (
						[ for ( scheduler in schedulers.items ) if ( scheduler.address in names ) scheduler.fullInfo ]
					)
				}
			);
		}
		else {
			msg.reply (
				JSON {
					Chime.key.schedulers -> JSONArray( [ for ( scheduler in schedulers.items ) scheduler.fullInfo ] )
				}
			);
		}
	}
	
}