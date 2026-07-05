-- =========================================================================
-- DoTimerSW_BaseDurations
-- 全语言通用底层数据表（以1级 SpellID 为主键，解耦文本匹配）
-- 针对 1.12 乌龟服 (Turtle WoW) 特性及长Buff（1小时）机制进行校准与优化
-- =========================================================================

DoTimerSW_BaseDurations = {

        [20549]   = { ["duration"] = 2,  ["multiplier"] = 1, isAoE = true },   -- 战争践踏 (War Stomp) 
	-- ========================================================
	-- 战士 (WARRIOR)
	-- ========================================================
	[772]   = { ["duration"] = 9,  ["multiplier"] = 1 },   -- 撕裂 (Rend) - Rank 1 
	[7386]  = { ["duration"] = 30, ["multiplier"] = 1 },   -- 破甲攻击 (Sunder Armor) - Rank 1
	[1160]  = { ["duration"] = 30, ["multiplier"] = 1, isAoE = true },   -- 挫志怒吼 (Demoralizing Shout) - Rank 1
	[6343]  = { ["duration"] = 10, ["multiplier"] = 1, isAoE = true },   -- 雷霆一击 (Thunder Clap) - Rank 1 (1.12标准持续10秒)
	[355]   = { ["duration"] = 3,  ["multiplier"] = 1 },   -- 嘲讽 (Taunt)
	[1715]  = { ["duration"] = 15, ["multiplier"] = 1 },   -- 断筋 (Hamstring) - Rank 1
	[676]   = { ["duration"] = 10, ["multiplier"] = 1 },   -- 缴械 (Disarm)
	[12323] = { ["duration"] = 6,  ["multiplier"] = 1, isAoE = true },   -- 刺耳怒吼 (Piercing Howl)
	[5246]  = { ["duration"] = 8,  ["multiplier"] = 1, isAoE = true },   -- 破胆怒吼 (Intimidating Shout)
	[12294] = { ["duration"] = 10, ["multiplier"] = 1 },   -- 致死打击 (Mortal Strike) - Rank 1

	-- ========================================================
	-- 圣骑士 (PALADIN)
	-- ========================================================
	[20166] = { ["duration"] = 10, ["multiplier"] = 1 },   -- 智慧审判 (Judgement of Wisdom) - Rank 1
	[20271] = { ["duration"] = 10, ["multiplier"] = 1 },   -- 光明审判 (Judgement of Light) - Rank 1
	[2878]  = { ["duration"] = 10, ["multiplier"] = 1 },   -- 超度亡灵 (Turn Undead) - Rank 1
	[853]   = { ["duration"] = 3,  ["multiplier"] = 1 },   -- 制裁之锤 (Hammer of Justice) - Rank 1
	[21183] = { ["duration"] = 10, ["multiplier"] = 1 },   -- 十字军审判 (Judgement of the Crusader) - Rank 1
	[20066] = { ["duration"] = 6,  ["multiplier"] = 1 },   -- 忏悔 (Repentance)
	
	-- 乌龟服机制：普通祝福延长至 15 分钟，强效祝福延长至 30 分钟 (配置 hideMain = true)
	[19740] = { ["duration"] = 15, ["multiplier"] = 60, ["hideMain"] = true }, -- 力量祝福 (Blessing of Might) - Rank 1
	[19742] = { ["duration"] = 15, ["multiplier"] = 60, ["hideMain"] = true }, -- 智慧祝福 (Blessing of Wisdom) - Rank 1
	[20217] = { ["duration"] = 15, ["multiplier"] = 60, ["hideMain"] = true }, -- 王者祝福 (Blessing of Kings)
	[1038]  = { ["duration"] = 15, ["multiplier"] = 60, ["hideMain"] = true }, -- 拯救祝福 (Blessing of Salvation)
	[19977] = { ["duration"] = 15, ["multiplier"] = 60, ["hideMain"] = true }, -- 光明祝福 (Blessing of Light) - Rank 1
	[20911] = { ["duration"] = 15, ["multiplier"] = 60, ["hideMain"] = true }, -- 庇护祝福 (Blessing of Sanctuary) - Rank 1
	
	[25782] = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 强效力量祝福 - Rank 1
	[25894] = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 强效智慧祝福 - Rank 1
	[25898] = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 强效王者祝福
	[25895] = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 强效拯救祝福
	[25890] = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 强效光明祝福 - Rank 1
	[25899] = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 强效庇护祝福 - Rank 1
	
	-- 乌龟服新增技能
	[46599] = { ["duration"] = 3,  ["multiplier"] = 1 },   -- 责难/挑衅 (Provocation) - 防骑单体嘲讽

	-- ========================================================
	-- 术士 (WARLOCK)
	-- ========================================================
	[702]   = { ["duration"] = 30, ["multiplier"] = 1 },   -- 语言诅咒 (Curse of Tongues) - Rank 1
	[172]   = { ["duration"] = 12, ["multiplier"] = 1 },   -- 腐蚀术 (Corruption) - Rank 1
	[348]   = { ["duration"] = 15, ["multiplier"] = 1 },   -- 献祭 (Immolate) - Rank 1
	[1122]  = { ["duration"] = 5,  ["multiplier"] = 60 },  -- 地狱火/召唤地狱火 (Inferno)
	[6789]  = { ["duration"] = 3,  ["multiplier"] = 1 },   -- 死亡缠绕 (Death Coil) - Rank 1
	[603]   = { ["duration"] = 1,  ["multiplier"] = 60 },  -- 末日诅咒 (Curse of Doom) - Rank 1 (持续1分钟)
	[710]   = { ["duration"] = 5,  ["multiplier"] = 60 },  -- 奴役恶魔 (Enslave Demon) - Rank 1
	[980]   = { ["duration"] = 24, ["multiplier"] = 1 },   -- 痛苦诅咒 (Curse of Agony) - Rank 1
	[704]   = { ["duration"] = 2,  ["multiplier"] = 60 },  -- 虚弱诅咒 (Curse of Weakness) - Rank 1
	[706]   = { ["duration"] = 2,  ["multiplier"] = 60 },  -- 鲁莽诅咒 (Curse of Recklessness) - Rank 1
	[17862] = { ["duration"] = 5,  ["multiplier"] = 60 },  -- 暗影诅咒 (Curse of Shadow) - Rank 1
	[717]   = { ["duration"] = 20, ["multiplier"] = 1 },   -- 放逐术 (Banish) - Rank 1
	[1490]  = { ["duration"] = 5,  ["multiplier"] = 60 },  -- 元素诅咒 (Curse of the Elements) - Rank 1
	[19244] = { ["duration"] = 8,  ["multiplier"] = 1 },   -- 法术封锁 (Spell Lock) - Rank 1
	[5782]  = { ["duration"] = 10, ["multiplier"] = 1 },   -- 恐惧术 (Fear) - Rank 1 (1级恐惧基础10秒)
	[5484]  = { ["duration"] = 10, ["multiplier"] = 1, isAoE = true },   -- 恐惧嚎叫 (Howl of Terror) - Rank 1 (基础10秒)
	[17877] = { ["duration"] = 5,  ["multiplier"] = 1 },   -- 暗影灼烧 (Shadowburn) - Rank 1
	[18265] = { ["duration"] = 30, ["multiplier"] = 1 },   -- 生命虹吸 (Siphon Life) - Rank 1
	[18223] = { ["duration"] = 12, ["multiplier"] = 1 },   -- 疲劳诅咒 (Curse of Exhaustion)
	[17800] = { ["duration"] = 12, ["multiplier"] = 1 },   -- 暗影易伤 (Shadow Vulnerability)
	-- 术士长 Buff 技能
	[5697]  = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 无尽呼吸 (Unending Breath)
	[132]   = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 侦测弱效隐形
	[2970]  = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 侦测隐形
	[11743] = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 侦测强效隐形

	-- ========================================================
	-- 牧师 (PRIEST)
	-- ========================================================
	[17]    = { ["duration"] = 30, ["multiplier"] = 1 },   -- 真言术：盾 (Power Word: Shield) - Rank 1 (Buff持续30秒)
	[6788]  = { ["duration"] = 15, ["multiplier"] = 1 },   -- 灵魂虚弱 (Weakened Soul) - 盾产生的Debuff，固定15秒且不可被击碎提前消失
	
	[9484]  = { ["duration"] = 30, ["multiplier"] = 1 },   -- 束缚亡灵 (Shackle Undead) - Rank 1
	[453]   = { ["duration"] = 15, ["multiplier"] = 1 },   -- 安抚心灵 (Mind Soothe) - Rank 1
	[552]   = { ["duration"] = 20, ["multiplier"] = 1 },   -- 驱除疾病 (Abolish Disease)
	[589]   = { ["duration"] = 18, ["multiplier"] = 1 },   -- 暗影字：痛 (Shadow Word: Pain) - Rank 1
	[8122]  = { ["duration"] = 8,  ["multiplier"] = 1, isAoE = true },   -- 心灵尖啸 (Psychic Scream) - Rank 1
	[2944]  = { ["duration"] = 24, ["multiplier"] = 1 },   -- 噬灵瘟疫 (Devouring Plague) - Rank 1
	[139]   = { ["duration"] = 15, ["multiplier"] = 1 },   -- 恢复 (Renew) - Rank 1
	[2943]  = { ["duration"] = 2,  ["multiplier"] = 60 },  -- 虚弱妖术 (Hex of Weakness) - Rank 1
	[15286] = { ["duration"] = 1,  ["multiplier"] = 60 },  -- 吸血鬼拥抱 (Vampiric Embrace)
	[10060] = { ["duration"] = 15, ["multiplier"] = 1 },   -- 能量灌注 (Power Infusion)
	[14914] = { ["duration"] = 10, ["multiplier"] = 1 },   -- 神圣之火 (Holy Fire) - Rank 1
	-- 牧师长 Buff 技能
	[1243]  = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 真言术：韧 - Rank 1 (30分钟)
	[14752] = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 神圣之灵 - Rank 1 (30分钟)
	[976]   = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 暗影防护 - Rank 1 (10分钟)
	[27683] = { ["duration"] = 20, ["multiplier"] = 60, ["hideMain"] = true }, -- 暗影防护祷言 - Rank 1 (20分钟)
	[6346]  = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 防护恐惧结界 (10分钟)
	
	-- 对齐技能书“1小时”文本逻辑（1 hour = 1 * 3600秒）
	[21562] = { ["duration"] = 1,  ["multiplier"] = 3600,["hideMain"] = true }, -- 坚韧祷言 - Rank 1
	[27681] = { ["duration"] = 1,  ["multiplier"] = 3600,["hideMain"] = true }, -- 精神祷言 - Rank 1

	-- ========================================================
	-- 德鲁伊 (DRUID)
	-- ========================================================
	[1079]  = { ["duration"] = 12, ["multiplier"] = 1 },   -- 割裂 (Rip) - Rank 1
	[770]   = { ["duration"] = 40, ["multiplier"] = 1 },   -- 精灵火 (Faerie Fire) - Rank 1
	[774]   = { ["duration"] = 12, ["multiplier"] = 1 },   -- 回春术 (Rejuvenation) - Rank 1
	[339]   = { ["duration"] = 12, ["multiplier"] = 1 },   -- 纠缠根须 (Entangling Roots) - Rank 1
	[2893]  = { ["duration"] = 8,  ["multiplier"] = 1 },   -- 驱毒术 (Abolish Poison)
	[1822]  = { ["duration"] = 9,  ["multiplier"] = 1 },   -- 斜掠 (Rake) - Rank 1
	[2637]  = { ["duration"] = 20, ["multiplier"] = 1 },   -- 休眠 (Hibernate) - Rank 1
	[8936]  = { ["duration"] = 20, ["multiplier"] = 1 },   -- 愈合 (Regrowth) - Rank 1
	[2908] = { ["duration"] = 15, ["multiplier"] = 1 },   -- 安抚野兽 (Soothe Animal) - Rank 1
	[5570]  = { ["duration"] = 12, ["multiplier"] = 1 },   -- 虫群 (Insect Swarm) - Rank 1
	[8921]  = { ["duration"] = 9,  ["multiplier"] = 1 },   -- 月火术 (Moonfire) - Rank 1 (1级DOT基础持续9秒)
	[29166] = { ["duration"] = 20, ["multiplier"] = 1 },   -- 激活 (Innervate)
	[5217]  = { ["duration"] = 6,  ["multiplier"] = 1 },   -- 猛虎之怒 (Tiger's Fury) - Rank 1 (基础持续6秒)
	[5176]  = { ["duration"] = 4,  ["multiplier"] = 1 },   -- 野性冲锋 (Feral Charge)
	[5209]  = { ["duration"] = 6,  ["multiplier"] = 1 },   -- 挑战咆哮 (Challenging Roar)
        [6795]  = { ["duration"] = 3,  ["multiplier"] = 1 },   -- 低吼 (Growl)
	[5211]  = { ["duration"] = 2,  ["multiplier"] = 1 },   -- 重击 (Bash) - Rank 1
	[99]    = { ["duration"] = 30, ["multiplier"] = 1, isAoE = true },   -- 挫志咆哮 (Demoralizing Roar) - Rank 1
	[9005]  = { ["duration"] = 18, ["multiplier"] = 1 },   -- 突袭 (Pounce) - Rank 1
	-- 德鲁伊长 Buff 技能
	[1126]  = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 野性印记 - Rank 1 (30分钟)
	[467]   = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 荆棘术 - Rank 1 (10分钟)
	
	-- 对齐技能书“1小时”文本逻辑（1 hour = 1 * 3600秒）
	[21849] = { ["duration"] = 1,  ["multiplier"] = 3600,["hideMain"] = true }, -- 野性赐福 - Rank 1
	
	-- 乌龟服新增技能
	[46200] = { ["duration"] = 12, ["multiplier"] = 1 },   -- 日炎术 (Sunfire) - Rank 1 (平衡德常规DOT)

	-- ========================================================
	-- 猎人 (HUNTER)
	-- ========================================================
	[3012]  = { ["duration"] = 20, ["multiplier"] = 1 },   -- 蝎毒钉刺 (Scorpid Sting) - Rank 1
	[1978]  = { ["duration"] = 15, ["multiplier"] = 1 },   -- 毒蛇钉刺 (Serpent Sting) - Rank 1
	[19386] = { ["duration"] = 12, ["multiplier"] = 2 },   -- 翼龙钉刺 (Wyvern Sting) - Rank 1
	[2974]  = { ["duration"] = 10, ["multiplier"] = 1 },   -- 剪翼 (Wing Clip) - Rank 1
	[3034]  = { ["duration"] = 8,  ["multiplier"] = 1 },   -- 蝰蛇钉刺 (Viper Sting) - Rank 1
	[1513]  = { ["duration"] = 10, ["multiplier"] = 1 },   -- 恐吓野兽 (Scare Beast) - Rank 1
	[5116]  = { ["duration"] = 4,  ["multiplier"] = 1 },   -- 震荡射击 (Concussive Shot)
	[19306] = { ["duration"] = 5,  ["multiplier"] = 1 },   -- 反击 (Counterattack) - Rank 1
	[1130]  = { ["duration"] = 2,  ["multiplier"] = 60 },  -- 猎人印记 (Hunter's Mark) - Rank 1 (持续2分钟)

	-- 乌龟服新增技能
	[46100] = { ["duration"] = 21, ["multiplier"] = 1 },   -- 割裂 (Lacerate) - Rank 1 (近战生存猎核心流血DOT)

	-- ========================================================
	-- 法师 (MAGE)
	-- ========================================================
	[118]   = { ["duration"] = 20, ["multiplier"] = 1 },   -- 变形术 (Polymorph) - Rank 1 (1级羊基础20秒)
	[28272] = { ["duration"] = 20, ["multiplier"] = 1 },   -- 变形术：猪 (对齐1级羊20秒)
	[28271] = { ["duration"] = 20, ["multiplier"] = 1 },   -- 变形术：龟 (对齐1级羊20秒)
	[122]   = { ["duration"] = 8,  ["multiplier"] = 1, isAoE = true },   -- 冰霜新星 (Frost Nova) - Rank 1
	-- 法师长 Buff 技能
	[1459]  = { ["duration"] = 30, ["multiplier"] = 60, ["hideMain"] = true }, -- 奥术智慧 - Rank 1 (30分钟)
	[604]   = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 抑制魔法 - Rank 1 (10分钟)
	[1008]  = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 放大魔法 - Rank 1 (10分钟)
	
	-- 对齐技能书“1小时”文本逻辑（1 hour = 1 * 3600秒）
	[23028] = { ["duration"] = 1,  ["multiplier"] = 3600,["hideMain"] = true }, -- 奥术光辉 - Rank 1
	
	-- 乌龟服新增技能
	[46300] = { ["duration"] = 6,  ["multiplier"] = 1 },   -- 奥术冲击 (Arcane Blast) - 技能层数Buff持续6秒

	-- ========================================================
	-- 潜行者 (ROGUE)
	-- ========================================================
	[1776]  = { ["duration"] = 4,   ["multiplier"] = 1 },   -- 凿击 (Gouge) - Rank 1
	[1833]  = { ["duration"] = 4,   ["multiplier"] = 1 },   -- 偷袭 (Cheap Shot) - Rank 1
	[6770]  = { ["duration"] = 25,  ["multiplier"] = 1 },   -- 闷棍 (Sap) - Rank 1
	[2094]  = { ["duration"] = 10,  ["multiplier"] = 1 },   -- 致盲 (Blind) - Rank 1
	[14251] = { ["duration"] = 6,   ["multiplier"] = 1 },   -- 反击 (Riposte) - Rank 1
	[1766]  = { ["duration"] = 5,   ["multiplier"] = 1 },   -- 脚踢 (Kick) - Rank 1
	[1725]  = { ["duration"] = 10,  ["multiplier"] = 1 },   -- 扰乱 (Distract) - Rank 1
	[16511] = { ["duration"] = 15,  ["multiplier"] = 1 },   -- 出血 (Hemorrhage) - Rank 1
	[703]   = { ["duration"] = 18,  ["multiplier"] = 1 },   -- 绞喉 (Garrote) - Rank 1 
	[8647]  = { ["duration"] = 30,  ["multiplier"] = 1 },   -- 破甲 (Expose Armor) - Rank 1
	[2823]  = { ["duration"] = 12,  ["multiplier"] = 1 },   -- 致命毒药 (Deadly Poison) - Rank 1
	[3408]  = { ["duration"] = 12,  ["multiplier"] = 1 },   -- 致残毒药 (Crippling Poison) - Rank 1
	[5761]  = { ["duration"] = 10,  ["multiplier"] = 1 },   -- 麻痹毒药 (Mind-numbing Poison) - Rank 1
	[13219] = { ["duration"] = 15,  ["multiplier"] = 1 },   -- 致伤毒药 (Wound Poison) - Rank 1

	-- ========================================================
	-- 萨满祭司 (SHAMAN)
	-- ========================================================
	[2484]  = { ["duration"] = 5,  ["multiplier"] = 1 },   -- 地缚图腾 (Earthbind Totem)
	[8050]  = { ["duration"] = 12, ["multiplier"] = 1 },   -- 烈焰震击 (Flame Shock) - Rank 1
	[16164] = { ["duration"] = 6,  ["multiplier"] = 1 },   -- 专注施法 (Focused Casting)
	[8056]  = { ["duration"] = 8,  ["multiplier"] = 1 },   -- 冰霜震击 (Frost Shock) - Rank 1
	[8177]  = { ["duration"] = 45, ["multiplier"] = 1 },   -- 根基图腾 (Grounding Totem)
	[16175] = { ["duration"] = 15, ["multiplier"] = 1 },   -- 治疗之道 (Healing Way)
	[16190] = { ["duration"] = 12, ["multiplier"] = 1 },   -- 法力潮汐图腾 (Mana Tide Totem) - Rank 1
	[17364] = { ["duration"] = 12, ["multiplier"] = 1 },   -- 风暴打击 (Stormstrike)
	-- 萨满长 Buff 技能
	[131]   = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 水上行走 (10分钟)
	[5715]  = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 水下呼吸 (10分钟)
	
	-- 乌龟服新增技能
	[46400] = { ["duration"] = 10, ["multiplier"] = 60, ["hideMain"] = true }, -- 大地盾 (Earth Shield) - Rank 1 (恢复萨大招，持续10分钟)

	-- ========================================================
	-- 宠物相关技能 (Pet Spells)
	-- ========================================================
	[2649]  = { ["duration"] = 3,  ["multiplier"] = 1 },   -- 低吼 (Growl) - Rank 1
	[24647] = { ["duration"] = 10, ["multiplier"] = 1 },   -- 蝎毒 (Scorpid Poison) - Rank 1
	[26090] = { ["duration"] = 2,  ["multiplier"] = 1 },   -- 丝网 (Web) - Rank 1
	[17735] = { ["duration"] = 30, ["multiplier"] = 1 },   -- 牺牲 (Sacrifice) - 虚空行者盾 - Rank 1
	[6358]  = { ["duration"] = 15, ["multiplier"] = 1 },   -- 诱惑 (Seduction) - 魅魔 - Rank 1
	[17843] = { ["duration"] = 30, ["multiplier"] = 1 },   -- 污染之血 (Tainted Blood) - 地狱犬 - Rank 1
}