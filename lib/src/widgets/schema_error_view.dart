import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/schema_validation_issue.dart';

/// Full-screen / inline UI shown when schema JSON validation fails.
///
/// Replaces the form so developers can see **where** the schema is wrong.
class SchemaErrorView extends StatelessWidget {
  /// Creates a [SchemaErrorView].
  const SchemaErrorView({
    super.key,
    required this.result,
    this.padding = const EdgeInsets.all(16),
    this.title = 'Invalid form schema',
    this.onRetry,
  });

  /// Validation result with path-aware issues.
  final SchemaValidationResult result;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  /// Header title.
  final String title;

  /// Optional retry callback.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errors = result.errors;
    final warnings = result.warnings;
    final maxWidth = MediaQuery.sizeOf(context).width > 720 ? 640.0 : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? constraints.maxWidth,
            ),
            child: SingleChildScrollView(
              padding: padding,
              child: Semantics(
                container: true,
                label: title,
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fix the JSON paths below, then reload the form.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy all errors',
                          onPressed: () => _copyAll(context),
                          icon: const Icon(Icons.copy_all_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (errors.isNotEmpty) ...[
                      Text(
                        '${errors.length} error${errors.length == 1 ? '' : 's'}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...errors.map((e) => _IssueCard(issue: e)),
                    ],
                    if (warnings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${warnings.length} warning${warnings.length == 1 ? '' : 's'}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...warnings.map((e) => _IssueCard(issue: e)),
                    ],
                    if (onRetry != null) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyAll(BuildContext context) async {
    final text = result.issues.map((e) => e.toString()).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Schema errors copied')),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final SchemaValidationIssue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = issue.severity == SchemaIssueSeverity.error;
    final color =
        isError ? theme.colorScheme.error : theme.colorScheme.tertiary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isError ? Icons.cancel_outlined : Icons.warning_amber_rounded,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    issue.path,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontFamily: 'monospace',
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy path',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: issue.path));
                  },
                  icon: const Icon(Icons.copy, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(issue.message, style: theme.textTheme.bodyMedium),
            if (issue.fieldKey != null) ...[
              const SizedBox(height: 4),
              Text(
                'Field key: ${issue.fieldKey}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (issue.expected != null || issue.actual != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (issue.expected != null)
                    _MetaChip(label: 'Expected', value: issue.expected!),
                  if (issue.actual != null)
                    _MetaChip(label: 'Got', value: issue.actual!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}
