# Fun Scripts

This directory contains entertaining and visually appealing PowerShell scripts to brighten your day and show off PowerShell's capabilities!

## Table of Contents

- [Available Scripts](#available-scripts)
  - [Get-ASCIIArt.ps1](#get-asciiartps1)
  - [Get-BinaryConverter.ps1](#get-binaryconverterps1)
  - [Get-Calendar.ps1](#get-calendarps1)
  - [Get-ChuckNorrisJoke.ps1](#get-chucknorrisjokeps1)
  - [Get-CoinFlip.ps1](#get-coinflipps1)
  - [Get-ColorPalette.ps1](#get-colorpaletteps1)
  - [Get-Countdown.ps1](#get-countdownps1)
  - [Get-Dice.ps1](#get-diceps1)
  - [Get-DigitalClock.ps1](#get-digitalclockps1)
  - [Get-Excuse.ps1](#get-excuseps1)
  - [Get-FortuneCookie.ps1](#get-fortunecookieps1)
  - [Get-Hangman.ps1](#get-hangmanps1)
  - [Get-MagicEightBall.ps1](#get-magiceightballps1)
  - [Get-MatrixEffect.ps1](#get-matrixeffectps1)
  - [Get-Maze.ps1](#get-mazeps1)
  - [Get-MorseCode.ps1](#get-morsecodeps1)
  - [Get-MotivationalPoster.ps1](#get-motivationalposterps1)
  - [Get-NumberGuessing.ps1](#get-numberguessingps1)
  - [Get-PasswordGenerator.ps1](#get-passwordgeneratorps1)
  - [Get-ProgressBarDemo.ps1](#get-progressbardemops1)
  - [Get-RandomColor.ps1](#get-randomcolorps1)
  - [Get-RandomQuote.ps1](#get-randomquoteps1)
  - [Get-RockPaperScissors.ps1](#get-rockpaperscissorsps1)
  - [Get-SlotMachine.ps1](#get-slotmachineps1)
  - [Get-StarWarsQuote.ps1](#get-starwarsquoteps1)
  - [Get-SystemInfo.ps1](#get-systeminfops1)
  - [Get-TeamNameGenerator.ps1](#get-teamnamegeneratorps1)
  - [Get-TemperatureConverter.ps1](#get-temperatureconverterps1)
  - [Get-TextToSpeech.ps1](#get-texttospeechps1)
  - [Get-TriviaGame.ps1](#get-triviagameps1)
  - [Get-TypingTest.ps1](#get-typingtestps1)
  - [Get-WeatherArt.ps1](#get-weatherartps1)
  - [Get-WordArt.ps1](#get-wordartps1)
- [Fun Use Cases](#fun-use-cases)
  - [PowerShell Profile](#powershell-profile)
  - [Team Presentations](#team-presentations)
  - [Meeting Icebreakers](#meeting-icebreakers)
  - [Games and Entertainment](#games-and-entertainment)
  - [Utilities with Flair](#utilities-with-flair)
- [Additional Resources](#additional-resources)

## Available Scripts

### Get-ASCIIArt.ps1

Generate ASCII art text with different styles and fonts.

**Features:**
- Multiple art styles (Banner, Block, Simple, Random)
- Colorful output
- Custom text input
- Pre-defined PowerShell banner

**Usage:**
```powershell
.\Get-ASCIIArt.ps1
.\Get-ASCIIArt.ps1 -Text "Hello World" -Style Banner
.\Get-ASCIIArt.ps1 -Style Random
```

---

### Get-BinaryConverter.ps1

Converts text to binary representation and vice versa.

**Source:** Inspired by [RapidTables ASCII to Binary](https://www.rapidtables.com/convert/number/ascii-to-binary.html) and [Microsoft Scripting Blog](https://devblogs.microsoft.com/scripting/)

**Usage:**
```powershell
.\Get-BinaryConverter.ps1 -Text "Hello"
.\Get-BinaryConverter.ps1 -Binary "01001000 01101001"
.\Get-BinaryConverter.ps1 -Text "PowerShell" -ShowTable
```

---

### Get-Calendar.ps1

Displays a colorful calendar for the current or specified month with today highlighted.

**Source:** Inspired by the Unix [`cal` command](https://en.wikipedia.org/wiki/Cal_(Unix)) and [Microsoft Scripting Blog](https://devblogs.microsoft.com/scripting/use-powershell-to-display-a-calendar/)

**Usage:**
```powershell
.\Get-Calendar.ps1
.\Get-Calendar.ps1 -Month 12 -Year 2025
```

---

### Get-ChuckNorrisJoke.ps1

Displays random Chuck Norris-style programming jokes with ASCII art.

**Source:** Jokes inspired by [Chuck Norris API](https://api.chucknorris.io/) and [r/ProgrammerHumor](https://www.reddit.com/r/ProgrammerHumor/)

**Usage:**
```powershell
.\Get-ChuckNorrisJoke.ps1
```

---

### Get-CoinFlip.ps1

Flips a virtual coin with ASCII art animation and statistics tracking.

**Source:** Inspired by [Microsoft Scripting Blog](https://devblogs.microsoft.com/scripting/) and [r/PowerShell](https://www.reddit.com/r/PowerShell/)

**Usage:**
```powershell
.\Get-CoinFlip.ps1
.\Get-CoinFlip.ps1 -Flips 10
```

---

### Get-ColorPalette.ps1

Displays the complete PowerShell console color palette with foreground and optional background combinations.

**Source:** Inspired by [Colorful PowerShell](https://devblogs.microsoft.com/scripting/colorful-powershell/) and [Stack Overflow](https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell)

**Usage:**
```powershell
.\Get-ColorPalette.ps1
.\Get-ColorPalette.ps1 -ShowBackground
```

---

### Get-Countdown.ps1

Displays a visual countdown timer with large ASCII numbers and color-coded alerts.

**Source:** Inspired by [Spiceworks Community](https://community.spiceworks.com/topic/post/6350583) and [Microsoft Scripting Blog](https://devblogs.microsoft.com/scripting/)

**Usage:**
```powershell
.\Get-Countdown.ps1
.\Get-Countdown.ps1 -Seconds 60 -Message "Meeting starts now!"
```

---

### Get-Dice.ps1

Rolls virtual dice with ASCII art die faces and totals.

**Source:** Inspired by [Weekend Scripter: Dice Roller](https://devblogs.microsoft.com/scripting/weekend-scripter-dice-roller/) and [PowerShell Gallery](https://www.powershellgallery.com/)

**Usage:**
```powershell
.\Get-Dice.ps1
.\Get-Dice.ps1 -Count 3 -Sides 20
```

---

### Get-DigitalClock.ps1

Displays a large digital clock using ASCII art digits with blinking colon separator.

**Source:** Inspired by [r/PowerShell ASCII Clock](https://www.reddit.com/r/PowerShell/comments/3zg3h3/ascii_clock/) and [Microsoft Scripting Blog](https://devblogs.microsoft.com/scripting/)

**Usage:**
```powershell
.\Get-DigitalClock.ps1
.\Get-DigitalClock.ps1 -Duration 60 -ShowDate
```

---

### Get-Excuse.ps1

Generates humorous random developer excuses for being late, missing deadlines, or explaining bugs.

**Source:** Inspired by [Programming Excuses](https://programmingexcuses.com/) and [r/ProgrammerHumor](https://www.reddit.com/r/ProgrammerHumor/)

**Usage:**
```powershell
.\Get-Excuse.ps1
.\Get-Excuse.ps1 -Category Bug
```

---

### Get-FortuneCookie.ps1

Displays a random fortune cookie message with ASCII art cookie.

**Source:** Inspired by the Unix [`fortune` command](https://en.wikipedia.org/wiki/Fortune_(Unix)) and [fortune-mod](https://github.com/shlomif/fortune-mod)

**Usage:**
```powershell
.\Get-FortuneCookie.ps1
```

---

### Get-Hangman.ps1

Play the classic Hangman word guessing game with ASCII art gallows and multiple word categories.

**Source:** Inspired by [r/PowerShell Hangman](https://www.reddit.com/r/PowerShell/comments/4h203c/hangman_game/) and [Rosetta Code Hangman](https://rosettacode.org/wiki/Hangman)

**Usage:**
```powershell
.\Get-Hangman.ps1
.\Get-Hangman.ps1 -Category Tech
```

---

### Get-MagicEightBall.ps1

Simulates the classic Magic 8-Ball toy with 20 authentic answers and ASCII art.

**Source:** Inspired by [Magic 8-Ball (Wikipedia)](https://en.wikipedia.org/wiki/Magic_8-ball) and [r/PowerShell](https://www.reddit.com/r/PowerShell/comments/5bj39l/magic_8ball/)

**Usage:**
```powershell
.\Get-MagicEightBall.ps1 -Question "Will I get a raise?"
.\Get-MagicEightBall.ps1
```

---

### Get-MatrixEffect.ps1

Creates a Matrix digital rain effect with green falling characters in the console.

**Source:** Inspired by [PowerShell Gallery](https://www.powershellgallery.com/) and [Guy Leech's PowerShell scripts](https://github.com/guyrleech/Microsoft-PowerShell/blob/master/dvdscreensaver.ps1)

**Usage:**
```powershell
.\Get-MatrixEffect.ps1
.\Get-MatrixEffect.ps1 -Duration 60 -Speed 30
```

---

### Get-Maze.ps1

Generates and displays a random ASCII maze using a recursive backtracker algorithm.

**Source:** Inspired by [Maze Generation Algorithm (Wikipedia)](https://en.wikipedia.org/wiki/Maze_generation_algorithm) and [r/PowerShell Maze Generator](https://www.reddit.com/r/PowerShell/comments/5nfwbr/maze_generator/)

**Usage:**
```powershell
.\Get-Maze.ps1
.\Get-Maze.ps1 -Width 20 -Height 12
```

---

### Get-MorseCode.ps1

Converts text to Morse code and Morse code back to text.

**Source:** Reference from [Morse Code (Wikipedia)](https://en.wikipedia.org/wiki/Morse_code) and [PowerShell Gallery](https://www.powershellgallery.com/)

**Usage:**
```powershell
.\Get-MorseCode.ps1 -Text "Hello World"
.\Get-MorseCode.ps1 -MorseCode ".... . .-.. .-.. --- / .-- --- .-. .-.. -.."
```

---

### Get-MotivationalPoster.ps1

Creates motivational poster-style displays with inspirational quotes and decorative borders.

**Source:** Inspired by [Microsoft Scripting Blog](https://devblogs.microsoft.com/scripting/) and [r/PowerShell](https://www.reddit.com/r/PowerShell/)

**Usage:**
```powershell
.\Get-MotivationalPoster.ps1
.\Get-MotivationalPoster.ps1 -Theme Coding
```

---

### Get-NumberGuessing.ps1

A number guessing game where the computer picks a random number and gives higher/lower hints.

**Source:** Inspired by [r/PowerShell Number Guessing Game](https://www.reddit.com/r/PowerShell/comments/3p1jba/powershell_number_guessing_game/) and [Microsoft Scripting Blog](https://devblogs.microsoft.com/scripting/)

**Usage:**
```powershell
.\Get-NumberGuessing.ps1
.\Get-NumberGuessing.ps1 -Max 1000
```

---

### Get-PasswordGenerator.ps1

Generates random secure passwords with configurable length and character requirements, plus strength analysis.

**Source:** Inspired by [Generating Passwords with PowerShell](https://devblogs.microsoft.com/scripting/generating-a-new-password-with-powershell/) and [PowerShell Gallery PasswordGenerator](https://www.powershellgallery.com/packages/PasswordGenerator/)

**Usage:**
```powershell
.\Get-PasswordGenerator.ps1
.\Get-PasswordGenerator.ps1 -Length 24 -Count 5
.\Get-PasswordGenerator.ps1 -NoSpecial
```

---

### Get-ProgressBarDemo.ps1

Demonstrates various progress bar styles: classic bar, blocks, dots, and spinner animations.

**Source:** Inspired by [r/PowerShell Progress Bar Examples](https://www.reddit.com/r/PowerShell/comments/7kd1yy/progress_bar_examples/) and [PowerShell Progress Bars](https://devblogs.microsoft.com/scripting/use-powershell-to-create-progress-bars/)

**Usage:**
```powershell
.\Get-ProgressBarDemo.ps1
.\Get-ProgressBarDemo.ps1 -Style Blocks -Duration 10
```

---

### Get-RandomColor.ps1

Generates random color samples showing console color names with RGB and hex values.

**Source:** Inspired by [Stack Overflow PowerShell Colors](https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell) and [Microsoft Scripting Blog](https://devblogs.microsoft.com/scripting/)

**Usage:**
```powershell
.\Get-RandomColor.ps1
.\Get-RandomColor.ps1 -Count 20
```

---

### Get-RandomQuote.ps1

Display random inspirational, tech, or funny quotes with ASCII art header.

**Usage:**
```powershell
.\Get-RandomQuote.ps1
.\Get-RandomQuote.ps1 -Category Tech
.\Get-RandomQuote.ps1 -Category Funny
```

---

### Get-RockPaperScissors.ps1

Play Rock, Paper, Scissors against the computer with ASCII art hand gestures and score tracking.

**Source:** Inspired by [r/PowerShell RPS Game](https://www.reddit.com/r/PowerShell/comments/86kf5e/) and [PowerShell Games](https://devblogs.microsoft.com/scripting/powershell-games/)

**Usage:**
```powershell
.\Get-RockPaperScissors.ps1 -Choice Rock
.\Get-RockPaperScissors.ps1 -Choice Paper -Rounds 5
```

---

### Get-SlotMachine.ps1

A console slot machine game with symbol matching, animated reels, and win statistics.

**Source:** Inspired by [r/PowerShell Slot Machine](https://www.reddit.com/r/PowerShell/comments/8z8fc4/slot_machine/) and [Rosetta Code Slot Machine](https://rosettacode.org/wiki/Slot_machine)

**Usage:**
```powershell
.\Get-SlotMachine.ps1
.\Get-SlotMachine.ps1 -Spins 5
```

---

### Get-StarWarsQuote.ps1

Displays memorable Star Wars quotes with character-specific ASCII art.

**Source:** Quotes from [StarWars.com](https://www.starwars.com/news/15-star-wars-quotes-to-use-in-everyday-life) and ASCII art inspired by [ASCII Art EU - Star Wars](https://www.asciiart.eu/movies/star-wars)

**Usage:**
```powershell
.\Get-StarWarsQuote.ps1
.\Get-StarWarsQuote.ps1 -Character Yoda
```

---

### Get-SystemInfo.ps1

Display comprehensive system information in a colorful, organized format with ASCII art banner.

**Usage:**
```powershell
.\Get-SystemInfo.ps1
.\Get-SystemInfo.ps1 -Detailed
```

---

### Get-TeamNameGenerator.ps1

Generates creative team names for hackathons, sprint teams, or project codenames.

**Source:** Inspired by [r/PowerShell](https://www.reddit.com/r/PowerShell/) and [Namelix](https://namelix.com/) naming patterns

**Usage:**
```powershell
.\Get-TeamNameGenerator.ps1
.\Get-TeamNameGenerator.ps1 -Count 10 -Style Epic
```

---

### Get-TemperatureConverter.ps1

Converts temperatures between Fahrenheit, Celsius, and Kelvin with visual indicators.

**Source:** Inspired by [PowerShell as Calculator](https://devblogs.microsoft.com/scripting/use-powershell-as-a-calculator/) and [PowerShell Gallery](https://www.powershellgallery.com/)

**Usage:**
```powershell
.\Get-TemperatureConverter.ps1 -Value 100 -From Celsius
.\Get-TemperatureConverter.ps1 -Value 72 -From Fahrenheit
```

---

### Get-TextToSpeech.ps1

Converts text to speech using the Windows .NET SpeechSynthesizer with configurable rate and volume.

**Source:** Inspired by [Make Your Computer Talk](https://devblogs.microsoft.com/scripting/use-powershell-to-make-your-computer-talk/) and [SpeechSynthesizer API](https://learn.microsoft.com/en-us/dotnet/api/system.speech.synthesis.speechsynthesizer)

**Usage:**
```powershell
.\Get-TextToSpeech.ps1 -Text "Hello from PowerShell!"
.\Get-TextToSpeech.ps1 -Text "Slow speech" -Rate -3
```

---

### Get-TriviaGame.ps1

A trivia quiz game with tech, science, and general knowledge questions, with score tracking.

**Source:** Inspired by [Open Trivia Database](https://opentdb.com/) and [r/PowerShell Trivia Game](https://www.reddit.com/r/PowerShell/comments/6r1kz8/trivia_game/)

**Usage:**
```powershell
.\Get-TriviaGame.ps1
.\Get-TriviaGame.ps1 -Questions 10
```

---

### Get-TypingTest.ps1

A typing speed test that measures words per minute and accuracy.

**Source:** Inspired by [r/PowerShell Typing Test](https://www.reddit.com/r/PowerShell/comments/gkmyij/) and [Monkeytype](https://monkeytype.com/) concept adapted for PowerShell

**Usage:**
```powershell
.\Get-TypingTest.ps1
```

---

### Get-WeatherArt.ps1

Displays ASCII art weather scenes for various conditions: sunny, rainy, cloudy, snowy, and stormy.

**Source:** ASCII art inspired by [ASCII Art EU - Weather](https://www.asciiart.eu/nature/weather) and [wttr.in](https://github.com/chubin/wttr.in)

**Usage:**
```powershell
.\Get-WeatherArt.ps1
.\Get-WeatherArt.ps1 -Weather Snowy
```

---

### Get-WordArt.ps1

Creates text with decorative word art borders in multiple styles (Double, Single, Stars, Hash, Rounded).

**Source:** Inspired by [ASCII Art in PowerShell](https://devblogs.microsoft.com/scripting/use-ascii-art-in-powershell/) and [ASCII Art EU - Text Art](https://www.asciiart.eu/text-art)

**Usage:**
```powershell
.\Get-WordArt.ps1 -Text "Hello World"
.\Get-WordArt.ps1 -Text "DevOps" -BorderStyle Stars
```

---

## Fun Use Cases

### PowerShell Profile

Add these to your PowerShell profile for a fun startup:

```powershell
# Add to $PROFILE

# Show a random quote when PowerShell starts
C:\Path\To\Scripts\Fun\Get-RandomQuote.ps1 -Category All

# Or show a fortune cookie
C:\Path\To\Scripts\Fun\Get-FortuneCookie.ps1

# Or show ASCII art
C:\Path\To\Scripts\Fun\Get-ASCIIArt.ps1 -Text "READY" -Style Block
```

### Team Presentations

```powershell
# Create impressive system info displays for demos
.\Get-SystemInfo.ps1 -Detailed

# Generate custom ASCII art for team names
.\Get-ASCIIArt.ps1 -Text "DevOps Team" -Style Block

# Generate team names for your next hackathon
.\Get-TeamNameGenerator.ps1 -Count 10 -Style Epic
```

### Meeting Icebreakers

```powershell
# Start team meetings with a random quote
.\Get-RandomQuote.ps1 -Category Funny

# Show a Star Wars quote
.\Get-StarWarsQuote.ps1

# Play a quick game of trivia
.\Get-TriviaGame.ps1 -Questions 3

# Get a developer excuse
.\Get-Excuse.ps1 -Category Bug
```

### Games and Entertainment

```powershell
# Play Rock Paper Scissors
.\Get-RockPaperScissors.ps1 -Rounds 5

# Try the Hangman game
.\Get-Hangman.ps1 -Category Tech

# Roll some dice
.\Get-Dice.ps1 -Count 3

# Try the slot machine
.\Get-SlotMachine.ps1 -Spins 5

# Guess a number
.\Get-NumberGuessing.ps1 -Max 100
```

### Utilities with Flair

```powershell
# Generate secure passwords
.\Get-PasswordGenerator.ps1 -Length 24 -Count 5

# Convert text to Morse code
.\Get-MorseCode.ps1 -Text "SOS"

# Convert text to binary
.\Get-BinaryConverter.ps1 -Text "Hello" -ShowTable

# Convert temperatures
.\Get-TemperatureConverter.ps1 -Value 100 -From Celsius

# Display a visual countdown
.\Get-Countdown.ps1 -Seconds 30
```

## Additional Resources

- [ASCII Art Archive](https://www.asciiart.eu/)
- [Box Drawing Characters](https://en.wikipedia.org/wiki/Box-drawing_character)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [Microsoft Scripting Blog](https://devblogs.microsoft.com/scripting/)
- [r/PowerShell](https://www.reddit.com/r/PowerShell/)
- [ANSI Escape Codes](https://en.wikipedia.org/wiki/ANSI_escape_code)

---

**Remember**: PowerShell isn't just for serious work - have some fun with it! 🎨🚀