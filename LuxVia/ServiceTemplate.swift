//
//  ServiceTemplate.swift
//  LuxVia
//
//  Funeral service templates for different traditions
//

import Foundation

/// Represents a template for a specific type of funeral service
struct ServiceTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let tradition: FuneralTradition
    let sections: [TemplateSection]
    
    init(id: UUID = UUID(), name: String, description: String, tradition: FuneralTradition, sections: [TemplateSection]) {
        self.id = id
        self.name = name
        self.description = description
        self.tradition = tradition
        self.sections = sections
    }
}

/// Represents a section within a service template
struct TemplateSection: Codable, Identifiable {
    let id: UUID
    let title: String
    let items: [TemplateItem]
    
    init(id: UUID = UUID(), title: String, items: [TemplateItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

/// Represents an item within a template section
struct TemplateItem: Codable, Identifiable {
    let id: UUID
    let type: ServiceItemType
    let title: String
    let subtitle: String?
    let customText: String?
    let isOptional: Bool
    
    init(id: UUID = UUID(), type: ServiceItemType, title: String, subtitle: String? = nil, customText: String? = nil, isOptional: Bool = false) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.customText = customText
        self.isOptional = isOptional
    }
}

/// Types of funeral traditions
enum FuneralTradition: String, Codable, CaseIterable {
    case catholic = "Catholic"
    case protestant = "Protestant"
    case secular = "Secular"
    case jewish = "Jewish"
    case muslim = "Muslim"
    case other = "Other"
}
