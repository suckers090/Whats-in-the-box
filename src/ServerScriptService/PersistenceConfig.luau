return {
	DataStoreName = "WITB_PlayerData_v1",
	StudioDataStoreName = "WITB_PlayerData_Studio_v1",
	-- Default Studio sessions stay local and never touch real player records.
	StudioPersistenceEnabled = false,
	AutosaveSeconds = 45,
	LeaseSeconds = 180,
	LeaseSafetySeconds = 30,
	Attempts = 3,
}
