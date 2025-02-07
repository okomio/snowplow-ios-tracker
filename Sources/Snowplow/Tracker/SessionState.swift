//  Copyright (c) 2013-2023 Snowplow Analytics Ltd. All rights reserved.
//
//  This program is licensed to you under the Apache License Version 2.0,
//  and you may not use this file except in compliance with the Apache License
//  Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
//  http://www.apache.org/licenses/LICENSE-2.0.
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the Apache License Version 2.0 is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
//  express or implied. See the Apache License Version 2.0 for the specific
//  language governing permissions and limitations there under.

import Foundation

@objc(SPSessionState)
public class SessionState: NSObject, State {
    @objc
    public private(set) var firstEventId: String?
    @objc
    public private(set) var firstEventTimestamp: String?
    @objc
    public private(set) var previousSessionId: String?
    @objc
    public private(set) var sessionId: String
    @objc
    public private(set) var sessionIndex = 0
    @objc
    public private(set) var storage: String
    @objc
    public private(set) var userId: String
    @objc
    public private (set) var eventIndex: Int
    @objc
    public private (set) var lastUpdate: Int64
    
    var sessionContext: [String : Any] {
        return sessionDictionary
    }
    var sessionContextOrig: [String : Any] {
        var copy = sessionDictionary
        copy.removeValue(forKey: kSPSessionLastUpdate)
        return copy
    }
    private var sessionDictionary: [String : Any] = [:]

    private func setupSessionContext() {
        sessionDictionary[kSPSessionPreviousId] = previousSessionId
        sessionDictionary[kSPSessionId] = sessionId
        sessionDictionary[kSPSessionFirstEventId] = firstEventId
        sessionDictionary[kSPSessionFirstEventTimestamp] = firstEventTimestamp
        sessionDictionary[kSPSessionIndex] = sessionIndex
        sessionDictionary[kSPSessionStorage] = storage
        sessionDictionary[kSPSessionUserId] = userId
        sessionDictionary[kSPSessionEventIndex] = eventIndex
        sessionDictionary[kSPSessionLastUpdate] = lastUpdate
    }

    init(firstEventId: String?, firstEventTimestamp: String?, sessionId: String, previousSessionId: String?, sessionIndex: Int, userId: String, eventIndex: Int, lastUpdate: Int64, storage: String) {
        self.firstEventId = firstEventId
        self.firstEventTimestamp = firstEventTimestamp
        self.sessionId = sessionId
        self.previousSessionId = previousSessionId
        self.sessionIndex = sessionIndex
        self.userId = userId
        self.storage = storage
        self.eventIndex = eventIndex
        self.lastUpdate = lastUpdate
        
        super.init()
        
        setupSessionContext()
    }

    init?(storedState: [String : Any]) {
        guard let sessionId = storedState[kSPSessionId] as? String,
              let sessionIndex = storedState[kSPSessionIndex] as? Int,
              let userId = storedState[kSPSessionUserId] as? String else {
            return nil
        }
        
        self.sessionId = sessionId
        self.sessionIndex = sessionIndex
        self.userId = userId
        
        self.previousSessionId = storedState[kSPSessionPreviousId] as? String
        
        // The FirstEventId should be stored in legacy persisted sessions even
        // if it wasn't used. Anyway we provide a default value in order to be
        // defensive and exclude any possible issue with a missing value.
        self.firstEventId = storedState[kSPSessionFirstEventId] as? String ?? "00000000-0000-0000-0000-000000000000"
        self.firstEventTimestamp = storedState[kSPSessionFirstEventTimestamp] as? String
        
        self.storage = storedState[kSPSessionStorage] as? String ?? "LOCAL_STORAGE"
        
        self.eventIndex = storedState[kSPSessionEventIndex] as? Int ?? 0
        self.lastUpdate = storedState[kSPSessionLastUpdate] as? Int64 ?? Utilities.getTimestamp().int64Value
        
        super.init()
        
        setupSessionContext()
    }
    
    public func incrementEventIndex(isSessionCheckerEnabled: Bool) {
        self.eventIndex += 1
        self.sessionDictionary[kSPSessionEventIndex] = self.eventIndex
        if isSessionCheckerEnabled {
            self.lastUpdate = Utilities.getTimestamp().int64Value
            self.sessionDictionary[kSPSessionLastUpdate] = self.lastUpdate
        }
    }
}
