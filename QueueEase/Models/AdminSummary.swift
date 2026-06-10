//
//  AdminSummary.swift
//  QueueEase
//
//  Created by Edward Geraldo Kristian on 10/06/26.
//

import Foundation

struct AdminSummary: Codable, Hashable {
    let totalTickets: Int
    let waitingTickets: Int
    let calledTickets: Int
    let checkedInTickets: Int
    let totalCustomers: Int
    let totalStaff: Int
    let totalAdmins: Int
    let activeCategories: Int
    let activeCounters: Int
    let todayTickets: Int?
    let completedTickets: Int?
}
