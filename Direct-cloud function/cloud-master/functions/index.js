const functions = require('firebase-functions');
const admin = require('firebase-admin');
const GeoFire = require('geofire');
const serviceAccount = require("./direct-f9743-firebase-adminsdk-l930b-4a27781b56.json");
const eventStartDateRoot = 'event_start_date';
const eventsRoot = 'events';
const deviceTokenRoot = 'device_token';

const userRoot = 'users';


admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://direct-f9743.firebaseio.com"
});


// cron job live event notification delivery
exports.liveEventsDelivery = functions.https.onRequest((request, response) => {
    // get the current date
    const today = new Date();
    const todayKey = today.toISOString().substring(0, 10);
    // get today's events reference
    const todayEventRef = admin.database().ref(`/${eventStartDateRoot}/${todayKey}`);
    // create a geofire reference for user location
    const userLocRef = admin.database().ref('/user_loc');
    const geoUserRef = new GeoFire(userLocRef);
    

    return todayEventRef.once('value').then(snapshot => {
        snapshot.forEach(function(eventSnapshot) {
            const eventKey = eventSnapshot.key;
            const startingTime = eventSnapshot.child('startTimeStamp').val();
            const endingTime = eventSnapshot.child('endTimeStamp').val();
            const currentTime = today.getTime() / 1000;
            // check whether the event is live

            if(currentTime >= startingTime && currentTime <= endingTime) {
                // this event is live right now, use geofire to select target audience to send out push notification
                console.log(`Happening ${eventKey}`);

                const liveEventRef = admin.database().ref(`/${eventsRoot}/${eventKey}`);
                liveEventRef.once('value').then(snapshot => {
                    const event_cor_lat = snapshot.child('location/cooridinate/lat').val();
                    const event_cor_long = snapshot.child('location/cooridinate/long').val();
                    const event_title = snapshot.child('title').val();
                    const location_name = snapshot.child('location/name').val();
                    
                    
                    // eventPrefList is a string that contains a list of category for the given events
                    // separated by a comma and whitespace
                    // etc: "Arts, Food, Music, School"
                    const eventPrefList = snapshot.child(`categoryList`).val();
                    
                    // split() strips the string by the delimiter and stores it into an array eventType
                    var eventType = eventPrefList.split(", ");

                    //construct the geo query
                    var geoQuery = geoUserRef.query({
                        center: [event_cor_lat, event_cor_long],
                        radius: 10000
                    });

                    var userKeys = [];
                    var onKeyEnteredRegistration = geoQuery.on("key_entered", function (key, location, distance) {
                      console.log(key + " entered query at " + location + " (" + distance + " km from center)");
                      
                        // userPref is the userkey filtered by geoQuery based on location
                        const userPref = admin.database().ref(`users/${key}/eventPreferences`).val();
                        
                        // go through the eventType array to see if the categories are matching to the user's preferences
                        eventType.forEach(function(event)
                        {
                            if (userPref.search(event)){
                                userKeys.push(key);
                            }
                        });
                    });

                    return geoQuery.on("ready", function() {
                        console.log("GeoQuery has loaded and fired all other events for initial data");
                        console.log(`The user keys are ${userKeys}`);


                        // get the device token for the given user
                        var reads = [];
                        userKeys.forEach(function(userKey){
                            const token_ref = admin.database().ref(`/${deviceTokenRoot}/${userKey}`);
                            const promise = token_ref.once('value');
                            reads.push(promise);
                            }
                        );
                         return Promise.all(reads).then(snapshots => {
                            // tokens for all the users that should receive this push notification
                            var tokens = snapshots.map(function(snapshot) {
                               return snapshot.val();
                            });

                            var payload = {
                              notification: {
                                title: location_name,
                                body: event_title,
                                badge: '1',
                                sound: 'default'
                              },
                              data: {
                                  eventKey: eventKey
                                }
                            };

                            return admin.messaging().sendToDevice(tokens, payload).then((resp) =>{
                                console.log("Live event delivery notification sent!", resp);

                                //put the cancel after first notifications here
                                admin.database().ref(`/${eventStartDateRoot}/${todayKey}`).child(`${eventKey}`).remove();                            });
                         });
                    });
                });
            } else {
                console.log(`Not Happening ${eventKey}`);
            }
         });
     });
});



 // cloud triggered
 // function: addEventToStartDate
 // description: when an event is added to real time database, add it to the event_start_date
exports.addEventToStartDate = functions.database.ref('/events/{pushId}').onCreate(event => {
    const eventVal = event.data.val()
    // get the event startDate
    const startDate = eventVal.startDateStringUTC; // 2017-11-2
    const startTimeStamp = eventVal.startTimeStamp;
    const endTimeStamp = eventVal.endTimeStamp;

    // get the event id
    const eventId = event.params.pushId;

    // add start date for this event under the event_start_date
    const e_start_date_ref =  admin.database().ref(`/${eventStartDateRoot}/${startDate}/${eventId}`)
    return e_start_date_ref.set({
        startTimeStamp: startTimeStamp,
        endTimeStamp: endTimeStamp
    });
})