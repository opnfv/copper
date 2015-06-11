Requirements
============
General requirements for a policy architecture are below, with an assessment of the current state of support for these across major OPNFV components (1=poor, 5=excellent).

  1. Polled monitoring: Exposure of state via request-response APIs.
  2. Notifications: Exposure of state via pub-sub APIs.
  3. Realtime/near-realtime notifications: Notifications that occur in actual or near realtime.
  4. Delegated policy: CRUD operations on policies that are distributed to specific components for local handling, including one/more of monitoring, violation reporting, and enforcement.
  5. Violation reporting: Reporting of conditions that represent a policy violation.
  6. Reactive enforcement: Enforcement actions taken in response to policy violation events.
  7. Proactive enforcement: Enforcement actions taken in advance of policy violation events, e.g. blocking actions that could result in a policy violation.
  8. Compliance auditing: Periodic auditing of state against policies.
  
.. list-table:: Table 1: Assessment of NFVI VIM Support for General Requirements
   :widths: 10 40 40
   :header-rows: 1

   * - #
     - OpenStack
     - OpenDaylight
     
   * - 1
     - 
     - 

   * - 2
     - 
     - 

   * - 3
     - 
     - 

   * - 4
     - 
     - 

   * - 5
     - 
     - 

   * - 6
     - 
     - 

   * - 7
     - 
     - 

   * - 8
     - 
     - 
