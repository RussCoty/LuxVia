# Funeral Service Templates - UI Flow Visualization

This document describes the visual user interface flow for the templates feature.

## 1. Service Tab - Main View

```
┌─────────────────────────────────────┐
│  ← Service | Details | Booklet      │
│  Edit                     📄  ?      │ ← New template button (📄)
├─────────────────────────────────────┤
│                                      │
│  • Welcome (welcome)                 │
│  • Opening Hymn (song)               │
│  • First Reading (reading)           │
│  • Responsorial Psalm (music)        │
│  • Gospel Reading (reading)          │
│  • Homily (reading)                  │
│  • Prayer of the Faithful (reading)  │
│  • ...                               │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
└─────────────────────────────────────┘
```

## 2. Template Selection Screen (After tapping 📄)

```
┌─────────────────────────────────────┐
│  Cancel    Service Templates   Apply │
├─────────────────────────────────────┤
│  Choose a template to start planning │
│  your service                        │
├─────────────────────────────────────┤
│                                      │
│  ┌─────────────────────────────────┐│
│  │ Catholic Requiem Mass        ✓  ││ ← Selected
│  │ Traditional Catholic funeral    ││
│  │ Mass following the Order of     ││
│  │ Christian Funerals              ││
│  │ Tradition: Catholic             ││
│  └─────────────────────────────────┘│
│                                      │
│  ┌─────────────────────────────────┐│
│  │ Protestant Funeral Service      ││
│  │ Traditional Protestant funeral  ││
│  │ service with hymns, scripture   ││
│  │ readings, and prayers           ││
│  │ Tradition: Protestant           ││
│  └─────────────────────────────────┘│
│                                      │
│  ┌─────────────────────────────────┐│
│  │ Secular Memorial Service        ││
│  │ Non-religious memorial service  ││
│  │ celebrating the life of the     ││
│  │ deceased                        ││
│  │ Tradition: Secular              ││
│  └─────────────────────────────────┘│
│                                      │
├─────────────────────────────────────┤
│  Templates provide a starting point │
│  with traditional sections and      │
│  items. You can customize all items │
│  after applying the template.       │
└─────────────────────────────────────┘
```

## 3. Template Preview Screen (After selecting a template)

```
┌─────────────────────────────────────┐
│  ← Catholic Requiem Mass            │
├─────────────────────────────────────┤
│  Introductory Rites                 │
├─────────────────────────────────────┤
│  🎵 Entrance Song                   │
│     Processional hymn               │
│                                      │
│  👋 Greeting                         │
│     Priest: In the name of the...   │
│                                      │
│  📖 Sprinkling with Holy Water      │
│     The priest sprinkles the...     │
│                                      │
│  📖 Placing of the Pall (Optional)  │
│     Family members or pallbea...    │
│                                      │
│  📖 Opening Prayer                   │
│     The priest leads the asse...    │
├─────────────────────────────────────┤
│  Liturgy of the Word                │
├─────────────────────────────────────┤
│  📖 First Reading                    │
│     From the Old Testament          │
│                                      │
│  🎵 Responsorial Psalm              │
│     Sung response                   │
│                                      │
│  📖 Second Reading (Optional)        │
│     From the New Testament          │
│                                      │
│  🎵 Gospel Acclamation              │
│     Alleluia (or other acclam...    │
│                                      │
│  📖 Gospel Reading                   │
│     Proclaimed by priest or d...    │
│                                      │
│  📖 Homily                           │
│     The priest reflects on th...    │
│                                      │
│  📖 Prayer of the Faithful          │
│     Intercessory prayers for...     │
├─────────────────────────────────────┤
│  Liturgy of the Eucharist           │
├─────────────────────────────────────┤
│  🎵 Offertory Hymn                  │
│     Preparation of gifts            │
│                                      │
│  ... (continues with more items)    │
├─────────────────────────────────────┤
│  This preview shows the template    │
│  structure. Items marked (Optional) │
│  can be included or removed based   │
│  on your preferences.               │
└─────────────────────────────────────┘
```

## 4. Apply Confirmation Alert (Empty Service)

```
┌─────────────────────────────────────┐
│                                      │
│        Template Applied              │
│                                      │
│  The Catholic Requiem Mass template │
│  has been applied to your service.  │
│  You can now customize it by        │
│  editing, reordering, or adding     │
│  items.                             │
│                                      │
│              [OK]                    │
│                                      │
└─────────────────────────────────────┘
```

## 5. Replace/Add Alert (Existing Service)

```
┌─────────────────────────────────────┐
│                                      │
│   Replace Existing Service?          │
│                                      │
│  You have items in your current     │
│  service. Do you want to replace    │
│  them with this template, or add    │
│  the template items to your         │
│  existing service?                  │
│                                      │
│  [Cancel] [Replace] [Add to Existing]│
│                                      │
└─────────────────────────────────────┘
```

## 6. Service Tab After Applying Template

```
┌─────────────────────────────────────┐
│  ← Service | Details | Booklet      │
│  Edit                     📄  ?      │
├─────────────────────────────────────┤
│                                      │
│  • Introductory Rites (welcome)     │ ← Section header
│  • Entrance Song (music)            │
│  • Greeting (welcome)               │
│  • Sprinkling with Holy Water...    │
│  • Placing of the Pall (reading)    │
│  • Opening Prayer (reading)         │
│  • Liturgy of the Word (welcome)    │ ← Section header
│  • First Reading (reading)          │
│  • Responsorial Psalm (music)       │
│  • Second Reading (reading)         │
│  • Gospel Acclamation (music)       │
│  • Gospel Reading (reading)         │
│  • Homily (reading)                 │
│  • Prayer of the Faithful (reading) │
│  • Liturgy of the Eucharist...      │ ← Section header
│  • Offertory Hymn (music)           │
│  • ...                              │
│                                      │
└─────────────────────────────────────┘
```

## 7. Edit Mode (Customizing Template)

```
┌─────────────────────────────────────┐
│  ← Service | Details | Booklet      │
│  Done                    📄  ?       │
├─────────────────────────────────────┤
│                                      │
│  ⊟ • Introductory Rites (welcome) ≡ │ ← Delete & drag handles
│  ⊟ • Entrance Song (music)        ≡ │
│  ⊟ • Greeting (welcome)           ≡ │
│  ⊟ • Sprinkling with Holy...      ≡ │
│  ⊟ • Placing of the Pall...       ≡ │
│  ⊟ • Opening Prayer (reading)     ≡ │
│  ⊟ • Liturgy of the Word...       ≡ │
│  ⊟ • First Reading (reading)      ≡ │
│  ⊟ • Responsorial Psalm (music)   ≡ │
│  ⊟ • Second Reading (reading)     ≡ │
│  ⊟ • Gospel Acclamation (music)   ≡ │
│  ⊟ • Gospel Reading (reading)     ≡ │
│  ⊟ • Homily (reading)             ≡ │
│  ⊟ • Prayer of the Faithful...    ≡ │
│  ⊟ • Liturgy of the Eucharist...  ≡ │
│  ⊟ • Offertory Hymn (music)       ≡ │
│                                      │
└─────────────────────────────────────┘
```

## Visual Design Elements

### Icons Used
- 📄 **Document icon**: Template button
- ? **Question mark**: Help button
- 🎵 **Musical note**: Music/song items
- 📖 **Book**: Reading items
- 👋 **Waving hand**: Welcome items
- 🙏 **Praying hands**: Farewell items
- ✓ **Checkmark**: Selected template
- ⊟ **Minus in circle**: Delete button
- ≡ **Three lines**: Drag handle

### Color Scheme
- System colors (iOS standard)
- Blue for selection and primary actions
- Green for success messages
- Red for destructive actions (delete)
- Gray for secondary text and placeholders

### Typography
- Bold: Template names, section titles
- Regular: Descriptions, item titles
- Small/Gray: Tradition type, subtitles

## User Interaction Patterns

1. **Single Tap**: Select item/template
2. **Tap "Apply"**: Apply selected template
3. **Tap Item**: View/edit item details
4. **Long Press + Drag**: Reorder (in edit mode)
5. **Swipe**: Not used (to prevent accidental deletes)
6. **Tap ⊟**: Delete item (with confirmation)

## Accessibility

- VoiceOver support for all elements
- Dynamic Type support
- High contrast mode compatible
- Clear touch targets (44x44 minimum)
- Descriptive labels for screen readers

## Responsive Design

- Works on all iPhone sizes
- iPad support with larger layouts
- Landscape orientation supported
- Adapts to different text sizes

This visualization shows how users will interact with the funeral service templates feature, providing a clear and intuitive experience for planning funeral services.
