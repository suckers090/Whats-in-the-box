-- Stable IDs: never reuse an ID for a different reward or increase its payout.
-- The server reads these values independently; clients use them only for display.
return {
	{id = "first_find", name = "First Find", required = 1, reward = 100},
	{id = "getting_started", name = "Getting Started", required = 3, reward = 500},
	{id = "original_five", name = "Original Five", required = 5, reward = 1500},
	{id = "warehouse_ten", name = "Getting Organized", required = 10, reward = 1000},
	{id = "collector_twenty", name = "Collector's Shelf", required = 20, reward = 2500},
	{id = "curator_thirty_five", name = "Warehouse Curator", required = 35, reward = 5000},
	{id = "expert_fifty", name = "Discovery Expert", required = 50, reward = 9000},
	{id = "complete_sixty", name = "Complete Manifest", required = 60, reward = 14000},
}
