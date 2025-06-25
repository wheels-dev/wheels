component {
    this.name = "WheelsTestEnvironment";
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 30, 0);
    
    // Include Wheels application events
    include "vendor/wheels/events/onapplicationstart.cfm";
    include "vendor/wheels/events/onrequeststart.cfm";
    include "vendor/wheels/events/onrequest.cfm";
    include "vendor/wheels/events/onrequestend.cfm";
    include "vendor/wheels/events/onerror.cfm";
    include "vendor/wheels/events/onmissingtemplate.cfm";
    include "vendor/wheels/events/onsessionstart.cfm";
    include "vendor/wheels/events/onsessionend.cfm";
}