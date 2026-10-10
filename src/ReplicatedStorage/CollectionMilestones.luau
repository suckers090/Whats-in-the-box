-- Stable IDs: never reuse an ID for a different reward or increase its payout.
-- The server reads these values independently; clients use them only for display.
return {
	{id = "first_find", name = "First Find", required = 1, reward = 100},
	{id = "getting_started", name = "Getting Started", required = 3, reward = 500},
	{id = "original_five", name = "Original Five", required = 5, reward = 1500},
}
