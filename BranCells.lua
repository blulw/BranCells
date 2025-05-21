--Creates an atlas for cards to use
SMODS.Atlas {
	-- Key for code to find it with
	key = "BranCells",
	-- The name of the file, for the code to pull the atlas from
	path = "jokers.png",
	-- Width of each sprite in 1x size
	px = 71,
	-- Height of each sprite in 1x size
	py = 95
}
--Creates an atlas for cards to use
SMODS.Atlas {
	-- Key for code to find it with
	key = "modicon",
	-- The name of the file, for the code to pull the atlas from
	path = "icon.png",
	-- Width of each sprite in 1x size
	px = 32,
	-- Height of each sprite in 1x size
	py = 32
}

SMODS.Atlas {
	
	key = "BranEnhancements",

	path = "Enhancers.png",

	px = 71,

	py = 95
}


SMODS.Joker {
	key = 'RNA',
	blueprint_compat = true,
	loc_txt = {
		name = 'RNA',
		text = {
			"If {C:attention}first discard {}of round",
			"has only {C:attention}1{} card, add a",
			"permanent copy to deck",
			"and draw it to {C:attention}hand"
		}
	},
	rarity = 3,
	-- Which atlas key to pull from.
	atlas = 'BranCells',
	-- This card's position on the atlas, starting at {x=0,y=0} for the very top left.
	pos = { x = 0, y = 0 },
	-- Cost of card in shop.
	cost = 6,
	-- The functioning part of the joker, looks at context to decide what step of scoring the game is on, and then gives a 'return' value if something activates.
	calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
            local eval = function()
                return G.GAME.current_round.discards_used == 0 and not G.RESET_JIGGLES
            end
            juice_card_until(card, eval, true)
        end
        if context.discard and context.full_hand and G.GAME.current_round.discards_used == 0 then
            if #context.full_hand == 1 then
                G.playing_card = (G.playing_card and G.playing_card + 1) or 1
				local copy_card = copy_card(context.full_hand[1], nil, nil, G.playing_card)
				copy_card:add_to_deck()
				G.deck.config.card_limit = G.deck.config.card_limit + 1
				table.insert(G.playing_cards, copy_card)
				G.hand:emplace(copy_card)
				copy_card.states.visible = nil

				G.E_MANAGER:add_event(Event({
					func = function()
						copy_card:start_materialize()
						return true
					end
				}))
				return {
					message = localize('k_copied_ex'),
					colour = G.C.CHIPS,
					func = function() -- This is for timing purposes, it runs after the message
						G.E_MANAGER:add_event(Event({
							func = function()
								SMODS.calculate_context({ playing_card_added = true, cards = { copy_card } })
								return true
							end
						}))
					end
				}
            end
        end
    end
}

SMODS.Joker {
	key = 'Apoptosis',
	blueprint_compat = false,
	loc_txt = {
		name = 'Apoptosis',
		text = {
			"On {C:attention}last discard {}of round",
			"{C:mult}destroy{} all discarded cards"
		}
	},
	rarity = 2,
	-- Which atlas key to pull from.
	atlas = 'BranCells',
	-- This card's position on the atlas, starting at {x=0,y=0} for the very top left.
	pos = { x = 1, y = 0 },
	-- Cost of card in shop.
	cost = 6,
	-- The functioning part of the joker, looks at context to decide what step of scoring the game is on, and then gives a 'return' value if something activates.
    calculate = function(self, card, context)
		if G.GAME.current_round.discards_left == 2 then
			local eval = function() return G.GAME.current_round.discards_left == 1 end
			juice_card_until(card, eval, true)
		end
		
		if context.discard and not context.blueprint then
			if G.GAME.current_round.discards_left == 1 then
				return {
					remove = true,
					card = context.other_card
				}
			end
		end
	end
}

SMODS.Joker {
    key = "Virus",
	loc_txt = {
		name = 'Virus',
		text = {
			"If played hand is a {C:attention}pair, ",
			"spread enhancement from the",
			"first {C:attention}scored card{} to all others"
		}
	},
	set_badges = function(self, card, badges)
		badges[#badges+1] = create_badge("Art - Raumfist", G.C.BLACK, G.C.WHITE, 0.8 )
	end,
    blueprint_compat = false,
	atlas = 'BranCells',
    rarity = 2,
    cost = 6,
    pos = { x = 2, y = 0 },
    calculate = function(self, card, context)
        if context.before and context.main_eval and context.scoring_name == 'Pair' then
            local first_card = context.scoring_hand[1]
            local enhancements = SMODS.get_enhancements(first_card)
            local upgraded = false
            for i, scored_card in ipairs(context.scoring_hand) do
                if i > 1 then
                    for enhancement in pairs(enhancements) do
                        scored_card:set_ability(enhancement, nil, true)
                        if enhancement ~= "m_base" then
                            upgraded = true
                        end
                    end
                    scored_card:juice_up()
                end
            end
            if upgraded then
                return {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.CHIPS,
                }
            end
        end
    end
}

SMODS.Joker {
    key = "Lactic",
	atlas = "BranCells",
    blueprint_compat = true,
    perishable_compat = false,
    rarity = 2,
    cost = 6,
    pos = { x = 0, y = 1 },
    config = { extra = { mult = 0, mult_mod = 5 } },
	set_badges = function(self, card, badges)
		badges[#badges+1] = create_badge("Art - Raumfist", G.C.BLACK, G.C.WHITE, 0.8 )
	end,
	loc_txt = {
		name = 'Lactic Acid',
		text = {
			"Gains {C:mult}+#2#{} Mult",
			"if played hand",
			"contains a {C:attention}Straight{}",
			"{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)"
		}
	},
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_mod } }
    end,
    calculate = function(self, card, context)
        if context.before and context.main_eval and not context.blueprint and next(context.poker_hands['Straight']) then
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.MULT,
            }
        end
        if context.joker_main then
            return {
                mult = card.ability.extra.mult
            }
        end
    end
}

SMODS.Joker {
    key = "PatientZero",
	atlas = "BranCells",
    blueprint_compat = false,
    perishable_compat = true,
    rarity = 1,
    cost = 5,
    pos = { x = 1, y = 1 },
	loc_txt = {
		name = 'Patient Zero',
		text = {
			"If {C:attention}first hand{} of round has",
			"only {C:attention}1{} card, add the",
			"{C:attention}Infected{} enhancement to it"
		}
	},
    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
            local eval = function() return G.GAME.current_round.hands_played == 0 and not G.RESET_JIGGLES end
            juice_card_until(card, eval, true)
        end
        if context.before and context.main_eval and G.GAME.current_round.hands_played == 0 and #context.full_hand == 1 then
            for i, scored_card in ipairs(context.scoring_hand) do
				scored_card:set_ability("m_bran_Infected", nil, true)
			end
        end
    end
}

SMODS.Joker {
    key = "InfectedJoker",
    blueprint_compat = true,
    rarity = 2,
    cost = 7,
    pos = { x = 2, y = 2 },
	loc_txt = {
		name = 'Infected Joker',
		text = {
			"Gives {X:mult,C:white}X0.5{} Mult",
			"for each {C:attention}Infected Card{}",
			"in your {c:attention}full deck",
			"{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)"
		}
	},
    config = { extra = { xmult = 0.5 } },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_bran_Infected

        local infected_count = 0
        if G.playing_cards then
            for _, playing_card in ipairs(G.playing_cards) do
                if SMODS.has_enhancement(playing_card, 'm_bran_Infected') then infected_count = infected_count + 1 end
            end
        end
        return { vars = { card.ability.extra.xmult, 1 + card.ability.extra.xmult * infected_count } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local infected_count = 0
            for _, playing_card in ipairs(G.playing_cards) do
                if SMODS.has_enhancement(playing_card, 'm_bran_Infected') then infected_count = infected_count + 1 end
            end
            return {
                Xmult = 1 + card.ability.extra.xmult * infected_count,
            }
        end
    end,
    in_pool = function(self, args)
        for _, playing_card in ipairs(G.playing_cards or {}) do
            if SMODS.has_enhancement(playing_card, 'm_bran_Infected') then
                return true
            end
        end
        return false
    end
}

SMODS.Enhancement({
	key = "Infected",
	atlas = "BranEnhancements",
	pos = { x = 0, y = 0 },
	loc_txt = {
		name = 'Infected',
		text = {
			"When scored, increase {C:chips}Chips",
			"by {C:chips}Chips{} of all other {C:attention}scored",
			"{C:attention}infected cards",
			"{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)"
		}
	},
	config = { extra = { chips = 5, chips_mod = 0 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips, card.ability.extra.chips_mod } }
	end,
	calculate = function(self, card, context, effect)
		if context.main_scoring and context.cardarea == G.play then
			card.ability.extra.chips_mod = 0
			for i, scored_card in ipairs(context.scoring_hand) do
				if scored_card ~= card then
					local enhancements = SMODS.get_enhancements(scored_card)
					for enhancement in pairs(enhancements) do
						if enhancement == "m_bran_Infected" then
							card.ability.extra.chips_mod = card.ability.extra.chips_mod + scored_card.ability.extra.chips
						end
					end
				end
			end
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chips_mod
			card:juice_up()
			return{
				message = localize('k_upgrade_ex'),
				colour = G.C.CHIPS,
				chips = card.ability.extra.chips,
			}
            end
		end
})

SMODS.Back{
	key = "Outbreak", 
	pos = {x = 0, y = 0},
    atlas = 'BranEnhancements',
	loc_txt = {
		name = 'Outbreak Deck',
		text = {
			"Start run with",
			"{C:attention}Patient Zero{} and {C:attention}Virus"
		}
	},
	
	unlocked = true,

    apply = function(self)
		G.E_MANAGER:add_event(Event({
			func = function()
				SMODS.add_card({ key = "j_bran_PatientZero" })
				SMODS.add_card({ key = "j_bran_Virus" })

				return true
			end
		}))
    end
}
