//
//  GitHubRepo.swift
//  DominionAppTest
//
//  Created by Gabriele Trabucco on 23/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

// MARK: - Repo

extension GitHubRepo: Identifiable { }

struct GitHubRepo: Codable {
    let id: Int
    let nodeId, name, fullName: String?
    let repoPrivate: Bool?
    let owner: Owner?
    let htmlUrl: String?
    let repoDescription: String?
    let fork: Bool?
    let url, forksUrl: String?
    let keysUrl, collaboratorsUrl: String?
    let teamsUrl, hooksUrl: String?
    let issueEventsUrl: String?
    let eventsUrl: String?
    let assigneesUrl, branchesUrl: String?
    let tagsUrl: String?
    let blobsUrl, gitTagsUrl, gitRefsUrl, treesUrl: String?
    let statusesUrl: String?
    let languagesUrl, stargazersUrl, contributorsUrl, subscribersUrl: String?
    let subscriptionUrl: String?
    let commitsUrl, gitCommitsUrl, commentsUrl, issueCommentUrl: String?
    let contentsUrl, compareUrl: String?
    let mergesUrl: String?
    let archiveUrl: String?
    let downloadsUrl: String?
    let issuesUrl, pullsUrl, milestonesUrl, notificationsUrl: String?
    let labelsUrl, releasesUrl: String?
    let deploymentsUrl: String?
    let createdAt, updatedAt, pushedAt: Date?
    let gitUrl, sshUrl: String?
    let cloneUrl: String?
    let svnUrl: String?
    let homepage: String?
    let size, stargazersCount, watchersCount: Int?
    let language: String?
    let hasIssues, hasProjects, hasDownloads, hasWiki: Bool?
    let hasPages: Bool?
    let forksCount: Int?
    let mirrorUrl: String?
    let archived, disabled: Bool?
    let openIssuesCount: Int?
    let license: License?
    let forks, openIssues, watchers: Int?
    let defaultBranch: String?
}

// MARK: - License
struct License: Codable {
    let key, name, spdxId: String?
    let url: String?
    let nodeId: String?
}

// MARK: - Owner
struct Owner: Codable {
    let login: String?
    let id: Int?
    let nodeId: String?
    let avatarUrl: String?
    let gravatarId: String?
    let url, htmlUrl, followersUrl: String?
    let followingUrl, gistsUrl, starredUrl: String?
    let subscriptionsUrl, organizationsUrl, reposUrl: String?
    let eventsUrl: String?
    let receivedEventsUrl: String?
    let type: String?
    let siteAdmin: Bool?
}
