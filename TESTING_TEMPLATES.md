# Testing the Funeral Service Templates Feature

## Overview
This document describes how to test the newly added funeral service templates feature in LuxVia.

## Files Added
- `LuxVia/ServiceTemplate.swift` - Data models for templates
- `LuxVia/TemplateManager.swift` - Template management and definitions
- `LuxVia/TemplateSelectionViewController.swift` - UI for selecting templates
- `LuxVia/TemplatePreviewViewController.swift` - UI for previewing templates
- `SERVICE_TEMPLATES_GUIDE.md` - User documentation

## Files Modified
- `LuxVia/ServiceViewController.swift` - Added template button and integration

## Manual Testing Steps

### 1. Build the Project
1. Open `LuxVia.xcodeproj` in Xcode
2. Build the project (⌘B)
3. Verify no compilation errors

### 2. Test Template Selection UI
1. Launch the app
2. Navigate to the **Service** tab
3. Look for the **document icon** (📄) in the top-right navigation bar
4. Tap the document icon
5. **Expected:** Template selection screen appears

### 3. Test Template List
In the template selection screen:
1. Verify three templates are listed:
   - Catholic Requiem Mass
   - Protestant Funeral Service
   - Secular Memorial Service
2. Each template should show:
   - Name (bold title)
   - Description
   - Tradition type

### 4. Test Template Preview
1. Tap on "Catholic Requiem Mass"
2. **Expected:** Preview screen shows template structure
3. Verify sections appear:
   - Introductory Rites
   - Liturgy of the Word
   - Liturgy of the Eucharist
   - Final Commendation
4. Each section should show multiple items with:
   - Type emoji (🎵 for music, 📖 for reading, etc.)
   - Item title
   - Optional subtitle or preview text
5. Go back and test the other templates similarly

### 5. Test Template Application (Empty Service)
1. Go back to template selection
2. Ensure your service is empty (or clear it via Edit mode)
3. Select "Catholic Requiem Mass"
4. Tap "Apply"
5. **Expected:** Confirmation alert appears
6. Tap "OK"
7. **Expected:** Return to Service tab with templated items

### 6. Verify Applied Template
In the Service tab:
1. Verify multiple items are now in your service order
2. Scroll through and check that sections are present:
   - Section headers (Welcome/Farewell type items)
   - Music items
   - Reading items
3. Tap on items to verify they have appropriate content

### 7. Test Template Application (With Existing Items)
1. Add a few custom items to your service
2. Tap the template icon again
3. Select a different template (e.g., "Protestant Funeral Service")
4. Tap "Apply"
5. **Expected:** Alert asks whether to "Replace" or "Add to Existing"
6. Test both options:
   - **Replace:** Should clear existing items and add template
   - **Add to Existing:** Should append template items to existing service

### 8. Test Template Customization
After applying a template:
1. Enter Edit mode
2. Reorder items by dragging
3. Delete optional items
4. Exit edit mode
5. Verify changes are preserved
6. Verify items can still be tapped to view content

### 9. Test Integration with Other Features
1. **PDF Booklet Generation:**
   - Apply a template
   - Navigate to "Booklet" tab
   - Verify PDF generates with templated items
   - Check that section headers and items appear correctly

2. **Service Details:**
   - Navigate to "Details" tab
   - Fill in service information
   - Go back to Service tab
   - Apply template
   - Return to Booklet tab
   - Verify both service details and template items appear in PDF

3. **Help System:**
   - Tap the help icon (?)
   - Select "Service Planning Help"
   - Verify the help text mentions templates

### 10. Test Edge Cases
1. **Empty Template Selection:**
   - Open template selection but don't select anything
   - Tap "Cancel"
   - Verify service remains unchanged

2. **Multiple Applications:**
   - Apply same template multiple times
   - Verify duplicates are added each time

3. **Mixed Content:**
   - Apply template
   - Add custom songs/readings manually
   - Verify mixed content works correctly

## Expected Behaviors

### Catholic Requiem Mass Template
Should include:
- 4 main sections
- ~20 items total
- Mix of music, readings, and prayers
- Section headers clearly labeled
- Optional items marked as "(Optional)"

### Protestant Funeral Service Template
Should include:
- 4 sections
- ~11 items total
- Balance of hymns, scripture, and prayers
- Clear progression from opening to closing

### Secular Memorial Service Template
Should include:
- 4 sections
- ~12 items total
- Focus on celebration of life
- Non-religious language
- Music and reading placeholders

## Known Limitations

1. Templates provide structure only - users need to select specific songs/readings from library
2. Section headers are added as Welcome/Farewell items (functional but could be enhanced)
3. No way to save custom templates (future enhancement)
4. No template editing UI (users customize after applying)

## Regression Testing

Verify existing functionality still works:
- [ ] Adding songs from library
- [ ] Adding readings from library
- [ ] Creating custom readings
- [ ] Reordering items in edit mode
- [ ] Deleting items
- [ ] Playing music from service order
- [ ] Generating PDF booklets
- [ ] Saving/loading service details

## Performance Testing

1. **Large Template Application:**
   - Apply Catholic Requiem Mass template (largest)
   - Verify UI remains responsive
   - Check memory usage is reasonable

2. **Rapid Template Switching:**
   - Apply multiple templates in succession
   - Verify no crashes or memory leaks

## Accessibility Testing

1. VoiceOver support (iOS)
2. Dynamic Type support
3. Proper contrast ratios
4. Meaningful accessibility labels

## Success Criteria

✅ All three templates load and display correctly  
✅ Template preview shows accurate structure  
✅ Templates can be applied to empty service  
✅ Templates can be added to existing service  
✅ Applied templates can be customized  
✅ PDF booklets include templated items  
✅ No crashes or compilation errors  
✅ Help documentation is clear and accessible  
✅ Existing features remain functional  

## Reporting Issues

If you find any issues:
1. Note the specific template and steps to reproduce
2. Check device logs for errors
3. Take screenshots if UI issues occur
4. Document expected vs actual behavior
