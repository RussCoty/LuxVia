//
//  TemplateManager.swift
//  LuxVia
//
//  Manages funeral service templates
//

import Foundation

class TemplateManager {
    static let shared = TemplateManager()
    
    private init() {}
    
    /// Returns all available templates
    func getAvailableTemplates() -> [ServiceTemplate] {
        return [
            createCatholicRequiemMassTemplate(),
            createProtestantFuneralTemplate(),
            createSecularMemorialTemplate()
        ]
    }
    
    /// Applies a template to the service order
    /// - Parameter template: The template to apply
    /// - Parameter clearExisting: Whether to clear existing service items first
    func applyTemplate(_ template: ServiceTemplate, clearExisting: Bool = true) {
        if clearExisting {
            ServiceOrderManager.shared.clear()
        }
        
        for section in template.sections {
            // Add section header as a welcome/farewell type
            let sectionHeader = ServiceItem(
                type: .welcome,
                title: section.title,
                subtitle: nil,
                customText: "--- Section: \(section.title) ---"
            )
            ServiceOrderManager.shared.add(sectionHeader)
            
            // Add items in the section
            for item in section.items {
                let serviceItem = ServiceItem(
                    type: item.type,
                    title: item.title,
                    subtitle: item.subtitle,
                    customText: item.customText
                )
                ServiceOrderManager.shared.add(serviceItem)
            }
        }
    }
    
    // MARK: - Template Definitions
    
    private func createCatholicRequiemMassTemplate() -> ServiceTemplate {
        return ServiceTemplate(
            name: "Catholic Requiem Mass",
            description: "Traditional Catholic funeral Mass following the Order of Christian Funerals",
            tradition: .catholic,
            sections: [
                // Introductory Rites
                TemplateSection(
                    title: "Introductory Rites",
                    items: [
                        TemplateItem(
                            type: .music,
                            title: "Entrance Song",
                            subtitle: "Processional hymn",
                            customText: "Select an appropriate hymn for the entrance procession"
                        ),
                        TemplateItem(
                            type: .welcome,
                            title: "Greeting",
                            customText: "Priest: In the name of the Father, and of the Son, and of the Holy Spirit.\nAll: Amen."
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Sprinkling with Holy Water",
                            customText: "The priest sprinkles the coffin with holy water, recalling the waters of baptism."
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Placing of the Pall",
                            customText: "Family members or pallbearers place the white pall over the coffin.",
                            isOptional: true
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Opening Prayer",
                            customText: "The priest leads the assembly in prayer."
                        )
                    ]
                ),
                
                // Liturgy of the Word
                TemplateSection(
                    title: "Liturgy of the Word",
                    items: [
                        TemplateItem(
                            type: .reading,
                            title: "First Reading",
                            subtitle: "From the Old Testament",
                            customText: "A reading from sacred scripture (e.g., Wisdom 3:1-9, Job 19:1, 23-27)"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Responsorial Psalm",
                            subtitle: "Sung response",
                            customText: "Common psalms: Psalm 23, Psalm 27, Psalm 103"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Second Reading",
                            subtitle: "From the New Testament",
                            customText: "A reading from the Epistles (e.g., Romans 8:31-35, 1 Corinthians 15:51-57)",
                            isOptional: true
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Gospel Acclamation",
                            customText: "Alleluia (or other acclamation during Lent)"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Gospel Reading",
                            subtitle: "Proclaimed by priest or deacon",
                            customText: "Gospel passage (e.g., John 11:17-27, John 14:1-6, Matthew 11:25-30)"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Homily",
                            customText: "The priest reflects on the scripture readings and the Christian hope of resurrection."
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Prayer of the Faithful",
                            customText: "Intercessory prayers for the deceased, the bereaved, and the community"
                        )
                    ]
                ),
                
                // Liturgy of the Eucharist
                TemplateSection(
                    title: "Liturgy of the Eucharist",
                    items: [
                        TemplateItem(
                            type: .music,
                            title: "Offertory Hymn",
                            subtitle: "Preparation of gifts",
                            customText: "Select an appropriate hymn for the preparation of the altar"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Eucharistic Prayer",
                            customText: "The priest consecrates the bread and wine"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Holy, Holy, Holy",
                            customText: "Sanctus"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Lord's Prayer",
                            customText: "Our Father, who art in heaven..."
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Communion Hymn",
                            customText: "Select an appropriate hymn for Holy Communion"
                        )
                    ]
                ),
                
                // Final Commendation
                TemplateSection(
                    title: "Final Commendation",
                    items: [
                        TemplateItem(
                            type: .reading,
                            title: "Invitation to Prayer",
                            customText: "The priest invites the assembly to pray for the deceased"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Words of Remembrance",
                            subtitle: "Eulogy",
                            customText: "Family member or friend may share memories (typically 3-5 minutes)",
                            isOptional: true
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Prayer of Commendation",
                            customText: "The priest prays for the eternal rest of the deceased"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Song of Farewell",
                            customText: "A hymn of farewell (e.g., 'Song of Farewell', 'May the Angels Lead You Into Paradise')"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Recessional Hymn",
                            subtitle: "Concluding song",
                            customText: "Select an appropriate hymn for the procession from the church"
                        )
                    ]
                )
            ]
        )
    }
    
    private func createProtestantFuneralTemplate() -> ServiceTemplate {
        return ServiceTemplate(
            name: "Protestant Funeral Service",
            description: "Traditional Protestant funeral service with hymns, scripture readings, and prayers",
            tradition: .protestant,
            sections: [
                TemplateSection(
                    title: "Opening",
                    items: [
                        TemplateItem(
                            type: .music,
                            title: "Opening Hymn",
                            customText: "Select an opening hymn"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Scripture Sentences",
                            customText: "Brief scripture passages of comfort and hope"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Opening Prayer",
                            customText: "Prayer invoking God's presence and comfort"
                        )
                    ]
                ),
                TemplateSection(
                    title: "Scripture and Reflection",
                    items: [
                        TemplateItem(
                            type: .reading,
                            title: "Old Testament Reading",
                            customText: "Reading from the Old Testament"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Hymn or Psalm",
                            customText: "Select a hymn or psalm"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "New Testament Reading",
                            customText: "Reading from the New Testament"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Sermon",
                            customText: "Message of hope and comfort from the minister"
                        )
                    ]
                ),
                TemplateSection(
                    title: "Remembrance",
                    items: [
                        TemplateItem(
                            type: .reading,
                            title: "Eulogy",
                            subtitle: "Words of Remembrance",
                            customText: "Family or friends share memories"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Special Music",
                            customText: "Hymn or song significant to the deceased",
                            isOptional: true
                        )
                    ]
                ),
                TemplateSection(
                    title: "Closing",
                    items: [
                        TemplateItem(
                            type: .reading,
                            title: "Prayers of Comfort",
                            customText: "Prayers for the bereaved and community"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Closing Hymn",
                            customText: "Select a closing hymn"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Benediction",
                            customText: "Final blessing and dismissal"
                        )
                    ]
                )
            ]
        )
    }
    
    private func createSecularMemorialTemplate() -> ServiceTemplate {
        return ServiceTemplate(
            name: "Secular Memorial Service",
            description: "Non-religious memorial service celebrating the life of the deceased",
            tradition: .secular,
            sections: [
                TemplateSection(
                    title: "Welcome",
                    items: [
                        TemplateItem(
                            type: .music,
                            title: "Opening Music",
                            subtitle: "Reflective instrumental or favorite song",
                            customText: "Select meaningful music to open the service"
                        ),
                        TemplateItem(
                            type: .welcome,
                            title: "Welcome and Introduction",
                            customText: "The officiant welcomes guests and introduces the purpose of gathering"
                        )
                    ]
                ),
                TemplateSection(
                    title: "Celebration of Life",
                    items: [
                        TemplateItem(
                            type: .reading,
                            title: "Reading or Poem",
                            subtitle: "Inspirational or meaningful text",
                            customText: "Select a favorite poem, literary passage, or inspirational reading"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Life Story",
                            subtitle: "Biography",
                            customText: "A narrative of the deceased's life, accomplishments, and character"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Musical Reflection",
                            customText: "A song or piece of music that was meaningful to the deceased"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Sharing of Memories",
                            subtitle: "Open microphone",
                            customText: "Invitation for attendees to share memories and stories",
                            isOptional: true
                        )
                    ]
                ),
                TemplateSection(
                    title: "Tribute",
                    items: [
                        TemplateItem(
                            type: .reading,
                            title: "Eulogy",
                            customText: "Formal tribute from family member or close friend"
                        ),
                        TemplateItem(
                            type: .reading,
                            title: "Reading or Poem",
                            subtitle: "Words of comfort",
                            customText: "Select an additional reading that provides comfort and hope"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Special Music",
                            customText: "Another meaningful song or musical piece",
                            isOptional: true
                        )
                    ]
                ),
                TemplateSection(
                    title: "Closing",
                    items: [
                        TemplateItem(
                            type: .reading,
                            title: "Closing Words",
                            customText: "Final reflections and acknowledgments from the officiant"
                        ),
                        TemplateItem(
                            type: .music,
                            title: "Closing Music",
                            subtitle: "Recessional",
                            customText: "Select music for the conclusion of the service"
                        ),
                        TemplateItem(
                            type: .farewell,
                            title: "Reception Information",
                            customText: "Announcement about gathering after the service",
                            isOptional: true
                        )
                    ]
                )
            ]
        )
    }
}
