import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/model/github_error_report.model.dart';
import 'package:paperless_mobile/core/widgets/error_report_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:paperless_mobile/extensions/dart_extensions.dart';

class GithubIssueService {
  static void openCreateGithubIssue({
    String? title,
    String? body,
    List<String>? labels,
    String? milestone,
    List<String>? assignees,
    String? project,
  }) {
    final Uri uri = Uri(
      scheme: "https",
      host: "github.com",
      path: "astubenbord/paperless-mobile/issues/new",
      queryParameters: {}
        ..tryPutIfAbsent('title', () => title)
        //..tryPutIfAbsent('body', () => body) //TODO: Figure out how to pass long body via url
        ..tryPutIfAbsent('labels', () => labels?.join(','))
        ..tryPutIfAbsent('milestone', () => milestone)
        ..tryPutIfAbsent('assignees', () => assignees?.join(','))
        ..tryPutIfAbsent('project', () => project),
    );
    log("[GitHubIssueService] Creating GitHub issue: " + uri.toString());
    launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static void createIssueFromError(
    BuildContext context, {
    StackTrace? stackTrace,
  }) async {
    final errorDescription = await Navigator.push<GithubErrorReport>(
      context,
      MaterialPageRoute(
        builder: (context) => ErrorReportPage(
          stackTrace: stackTrace,
        ),
      ),
    );
    if (errorDescription == null) {
      return;
    }

    return openCreateGithubIssue(
      title: errorDescription.shortDescription,
      body: errorDescription.longDescription ?? '',
      labels: ['error report'],
    );
  }
}
