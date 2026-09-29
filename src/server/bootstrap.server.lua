-- Server entry. Ordered startup only — modules stay cheap at require-time.

local SessionService = require(script.Parent.SessionService)

SessionService.Start()
