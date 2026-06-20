extends Node

# Returns a random bill Dictionary for the current month.
# Bills are influenced by the player's ideology and current economy.

const BILL_POOL : Array = [
	{
		"name": "Universal Healthcare Act",
		"desc": "Expand public healthcare coverage to all citizens. Popular with workers, costly to implement.",
		"seats_needed": 151,
		"gdp_effect": -0.3, "unemployment_effect": -0.2, "deficit_effect": 0.8,
		"approval_effect": 9.0, "ideology_lean": -4.0
	},
	{
		"name": "Corporate Tax Cut Bill",
		"desc": "Reduce corporate tax rate by 5%. Stimulates investment but widens inequality.",
		"seats_needed": 151,
		"gdp_effect": 0.6, "unemployment_effect": -0.3, "deficit_effect": 1.2,
		"approval_effect": -3.0, "ideology_lean": 5.0
	},
	{
		"name": "Green Energy Transition Fund",
		"desc": "A £50bn fund for renewable energy infrastructure over 10 years.",
		"seats_needed": 151,
		"gdp_effect": 0.2, "unemployment_effect": -0.4, "deficit_effect": 0.6,
		"approval_effect": 6.0, "ideology_lean": -5.0
	},
	{
		"name": "Border Security Enhancement",
		"desc": "Increase border enforcement funding and tighten immigration rules.",
		"seats_needed": 151,
		"gdp_effect": -0.1, "unemployment_effect": 0.1, "deficit_effect": 0.4,
		"approval_effect": 2.0, "ideology_lean": 6.0
	},
	{
		"name": "Austerity Budget",
		"desc": "Cut public spending by 8% across departments to reduce the deficit.",
		"seats_needed": 151,
		"gdp_effect": -0.5, "unemployment_effect": 0.5, "deficit_effect": -1.5,
		"approval_effect": -8.0, "ideology_lean": 4.0
	},
	{
		"name": "Workers Rights Expansion",
		"desc": "Mandate a 4-day week and strengthen union bargaining rights.",
		"seats_needed": 151,
		"gdp_effect": -0.2, "unemployment_effect": 0.3, "deficit_effect": 0.1,
		"approval_effect": 7.0, "ideology_lean": -6.0
	},
	{
		"name": "Free University Tuition Act",
		"desc": "Abolish tuition fees and fund universities through general taxation.",
		"seats_needed": 151,
		"gdp_effect": 0.1, "unemployment_effect": -0.1, "deficit_effect": 0.7,
		"approval_effect": 8.0, "ideology_lean": -4.0
	},
	{
		"name": "National Infrastructure Plan",
		"desc": "£80bn investment in roads, rail, and broadband over 5 years.",
		"seats_needed": 151,
		"gdp_effect": 0.7, "unemployment_effect": -0.6, "deficit_effect": 1.0,
		"approval_effect": 5.0, "ideology_lean": 0.0
	},
	{
		"name": "Privatisation of Rail Network",
		"desc": "Sell state-owned rail assets to private operators.",
		"seats_needed": 151,
		"gdp_effect": 0.3, "unemployment_effect": 0.2, "deficit_effect": -0.5,
		"approval_effect": -6.0, "ideology_lean": 7.0
	},
	{
		"name": "Emergency Housing Bill",
		"desc": "Build 200,000 social homes over 3 years to tackle the housing crisis.",
		"seats_needed": 151,
		"gdp_effect": 0.4, "unemployment_effect": -0.5, "deficit_effect": 0.9,
		"approval_effect": 10.0, "ideology_lean": -3.0
	},
]

func get_random_bill() -> Dictionary:
	var index = randi() % BILL_POOL.size()
	return BILL_POOL[index].duplicate()