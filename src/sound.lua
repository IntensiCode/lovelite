local sound = {}

-- Constants for our synthesis
local SAMPLE_RATE = 44100
local MAX_AMPLITUDE = 0.3  -- Prevent clipping

---Generate a simple impact sound
---@param frequency number Base frequency in Hz
---@param duration number Duration in seconds
---@param decay number Decay rate (higher = faster decay)
---@return love.SoundData
local function generate_impact(frequency, duration, decay)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        local amplitude = MAX_AMPLITUDE * math.exp(-decay * t)
        local value = amplitude * math.sin(2 * math.pi * frequency * t)
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a magic effect sound
---@param base_freq number Base frequency in Hz
---@param mod_freq number Modulation frequency in Hz
---@param duration number Duration in seconds
---@param decay number Decay rate
---@return love.SoundData
local function generate_magic(base_freq, mod_freq, duration, decay)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        local amplitude = MAX_AMPLITUDE * math.exp(-decay * t)
        local mod = math.sin(2 * math.pi * mod_freq * t)
        local freq = base_freq + mod * 100  -- Frequency modulation
        local value = amplitude * math.sin(2 * math.pi * freq * t)
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a pickup sound (ascending tones)
---@param start_freq number Starting frequency in Hz
---@param end_freq number Ending frequency in Hz
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_pickup(start_freq, end_freq, duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        local freq = start_freq + (end_freq - start_freq) * (t / duration)
        local amplitude = MAX_AMPLITUDE * (1 - t / duration)
        local value = amplitude * math.sin(2 * math.pi * freq * t)
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a ghost sound (spooky woo)
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_ghost(duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        -- Create a ghostly wail that rises and falls
        local freq = 200 + math.sin(t * 8) * 100
        local amplitude = MAX_AMPLITUDE * math.exp(-3 * t) * (1 + math.sin(t * 16)) / 2
        local value = amplitude * math.sin(2 * math.pi * freq * t)
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a splat sound (for rats/bats)
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_splat(duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        -- Create a quick thump followed by a splatter
        local thump = math.sin(2 * math.pi * 100 * t) * math.exp(-30 * t)
        local splat = math.random() * math.exp(-10 * t) * math.sin(2 * math.pi * 300 * t)
        local value = MAX_AMPLITUDE * (thump + splat * 0.5)
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a shatter sound (for knights/armor)
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_shatter(duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    -- Generate several quick, high-pitched impacts
    local impacts = {}
    for i = 1, 5 do
        impacts[i] = {
            time = math.random() * duration * 0.8,
            freq = 800 + math.random() * 400,
            amp = 0.5 + math.random() * 0.5
        }
    end

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        local value = 0
        for _, impact in ipairs(impacts) do
            if t >= impact.time then
                local dt = t - impact.time
                value = value + impact.amp * math.sin(2 * math.pi * impact.freq * dt) * math.exp(-20 * dt)
            end
        end
        sound_data:setSample(i, MAX_AMPLITUDE * value)
    end

    return sound_data
end

---Generate a magical death sound
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_magic_death(duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        -- Create a mystical descending tone with sparkles
        local base = math.sin(2 * math.pi * (600 - t * 300) * t)
        local sparkle = 0
        for j = 1, 3 do
            sparkle = sparkle + math.sin(2 * math.pi * (1200 + j * 400) * t) * math.exp(-20 * t)
        end
        local value = MAX_AMPLITUDE * (base * math.exp(-3 * t) + sparkle * 0.3)
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a player death sound (dramatic!)
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_player_death(duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        -- Create a dramatic descending tone with reverb
        local main = math.sin(2 * math.pi * (400 - t * 200) * t)
        local reverb = math.sin(2 * math.pi * (200 - t * 100) * t) * math.sin(t * 8)
        local value = MAX_AMPLITUDE * (main * math.exp(-2 * t) + reverb * 0.5 * math.exp(-1 * t))
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a swoosh sound for melee weapons
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_swoosh(duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        -- Create a rising then falling frequency for the swoosh
        local freq = 500 + 1000 * t * (1 - t) * 4  -- Peaks in the middle
        -- Add some noise for air friction
        local noise = math.random() * 0.3
        local amplitude = MAX_AMPLITUDE * math.exp(-8 * t) * (1 - t)
        local value = amplitude * (math.sin(2 * math.pi * freq * t) + noise)
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a magical swoosh sound
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_magic_swoosh(duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        -- Strong base swoosh with rising pitch
        local base_freq = 300 + t * 600  -- Rising from 300Hz to 900Hz
        local base = math.sin(2 * math.pi * base_freq * t)
        
        -- Add strong magical chime overtones
        local chime = 0
        for j = 1, 3 do
            local chime_freq = 900 + j * 300
            chime = chime + 0.4 * math.sin(2 * math.pi * chime_freq * t)
        end
        
        -- Add a strong "whoosh" noise component
        local noise = math.random() * 0.3
        
        -- Combine with a sharp attack and medium decay
        local amplitude = MAX_AMPLITUDE * math.exp(-10 * t) * (1 - t/duration)
        local value = amplitude * (base * 0.5 + chime * 0.3 + noise * 0.2)
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a melee wall hit sound (clang with splatter)
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_melee_wall_hit(duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        -- Metal clang (high frequency with quick decay)
        local clang = math.sin(2 * math.pi * 1200 * t) * math.exp(-30 * t)
        -- Add some lower frequency resonance
        local resonance = math.sin(2 * math.pi * 400 * t) * math.exp(-15 * t)
        -- Add debris/splatter effect
        local debris = 0
        for j = 1, 3 do
            debris = debris + math.random() * math.exp(-20 * (t + j * 0.02)) * 
                    math.sin(2 * math.pi * (600 + j * 200) * t)
        end
        
        local value = MAX_AMPLITUDE * (clang * 0.6 + resonance * 0.3 + debris * 0.2)
        sound_data:setSample(i, value)
    end

    return sound_data
end

---Generate a magic wall hit sound (mystical dispersion)
---@param duration number Duration in seconds
---@return love.SoundData
local function generate_magic_wall_hit(duration)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sound_data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        -- Strong initial impact
        local impact = math.sin(2 * math.pi * 400 * t) * math.exp(-15 * t)
        
        -- Add crystal-like shattering effect
        local shatter = 0
        for j = 1, 4 do
            local freq = 800 + j * 400
            shatter = shatter + math.random() * math.exp(-20 * (t + j * 0.02)) * 
                     math.sin(2 * math.pi * freq * t)
        end
        
        -- Add magical dispersion
        local disperse = math.sin(2 * math.pi * (600 + t * 300) * t) * math.exp(-8 * t)
        
        -- Combine all elements with stronger initial presence
        local value = MAX_AMPLITUDE * (impact * 0.5 + shatter * 0.3 + disperse * 0.2)
        sound_data:setSample(i, value)
    end

    return sound_data
end

-- Cache for our generated sounds
local sound_cache = {}

---@param opts? {reset: boolean} Options for loading (default: {reset = true})
function sound.load(opts)
    opts = opts or { reset = true }

    -- Add sound to global game variable (this is constant and only needs to be set once)
    _game = _game or {}
    _game.sound = sound

    -- Sound effects are resources that only need to be loaded once
    -- They don't represent game state that needs to be reset
    if sound_cache.melee_hit then return end

    -- Basic gameplay sounds
    sound_cache.melee_hit = love.audio.newSource(
        generate_impact(150, 0.1, 40),
        "static"
    )
    sound_cache.magic = love.audio.newSource(
        generate_magic(400, 8, 0.2, 10),
        "static"
    )
    sound_cache.ice = love.audio.newSource(
        generate_magic(800, 12, 0.3, 8),
        "static"
    )
    sound_cache.pickup = love.audio.newSource(
        generate_pickup(300, 600, 0.15),
        "static"
    )
    sound_cache.player_hit = love.audio.newSource(
        generate_impact(80, 0.2, 20),
        "static"
    )

    -- Projectile sounds
    sound_cache.melee_swoosh = love.audio.newSource(
        generate_swoosh(0.2),
        "static"
    )
    sound_cache.magic_swoosh = love.audio.newSource(
        generate_magic_swoosh(0.3),
        "static"
    )
    sound_cache.melee_wall_hit = love.audio.newSource(
        generate_melee_wall_hit(0.3),
        "static"
    )
    sound_cache.magic_wall_hit = love.audio.newSource(
        generate_magic_wall_hit(0.4),
        "static"
    )

    -- Death sounds
    sound_cache.player_death = love.audio.newSource(
        generate_player_death(0.8),
        "static"
    )
    sound_cache.ghost_death = love.audio.newSource(
        generate_ghost(0.5),
        "static"
    )
    sound_cache.rat_death = love.audio.newSource(
        generate_splat(0.2),
        "static"
    )
    sound_cache.bat_death = love.audio.newSource(
        generate_splat(0.2),
        "static"
    )
    sound_cache.knight_death = love.audio.newSource(
        generate_shatter(0.4),
        "static"
    )
    sound_cache.magic_death = love.audio.newSource(
        generate_magic_death(0.6),
        "static"
    )
end

---Play a sound effect
---@param name string The name of the sound to play
---@param volume number? Optional volume multiplier (0-1)
function sound.play(name, volume)
    if sound_cache[name] then
        -- Clone the source so multiple instances can play simultaneously
        local source = sound_cache[name]:clone()
        source:setVolume(volume or 1)
        source:play()
    end
end

---Play appropriate death sound based on enemy type
---@param enemy_type string The type of enemy that died
function sound.play_death(enemy_type)
    if enemy_type == "ghost" then
        sound.play("ghost_death", 0.8)
    elseif enemy_type == "rat" or enemy_type == "bat" then
        sound.play("rat_death", 0.7)
    elseif enemy_type == "knight" or enemy_type == "warrior" then
        sound.play("knight_death", 0.9)
    elseif enemy_type == "wizard" or enemy_type == "mage" or enemy_type == "necromancer" then
        sound.play("magic_death", 0.8)
    else
        -- Default to magic death sound for unknown types
        sound.play("magic_death", 0.6)
    end
end

return sound 