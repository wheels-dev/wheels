component {
    this.name = "WheelsTestEnvironment";
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 30, 0);
    
    // Include Wheels application events
    include "wheels/events/onapplicationstart.cfm";
    include "wheels/events/onrequeststart.cfm";
    include "wheels/events/onrequest.cfm";
    include "wheels/events/onrequestend.cfm";
    include "wheels/events/onerror.cfm";
    include "wheels/events/onmissingtemplate.cfm";
    include "wheels/events/onsessionstart.cfm";
    include "wheels/events/onsessionend.cfm";
}