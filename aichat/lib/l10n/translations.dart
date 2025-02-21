import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'AIChat',
      'chats': 'Chats',
      'settings': 'Settings',
      'api_settings': 'API Settings',
      'select_api': 'Select API',
      'clear_context': 'Clear Context',
      'clear_messages': 'Clear Messages',
      'add_attachment': 'Add Attachment',
      'type_message': 'Type a message',
      'no_messages': 'No messages yet',
      'start_conversation': 'Start the conversation',
      'copy_message': 'Copy Message',
      'message_copied': 'Message copied to clipboard',
      'add_to_favorites': 'Add to Favorites',
      'remove_from_favorites': 'Remove from Favorites',
      'delete_message': 'Delete Message',
      'delete_config': 'Delete Configuration',
      'delete_confirm':
          'Are you sure you want to delete this? This action cannot be undone.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'save': 'Save',
      'edit': 'Edit',
      'copy': 'Copy',
      'no_api_selected': 'No API Selected',
      'stop_generating': 'Stop Generating',
      'continue_generating': 'Continue',
      'error': 'Error',
      'unknown_error': 'Unknown error occurred',
    },
    'zh': {
      'app_title': 'AI聊天',
      'chats': '聊天',
      'settings': '设置',
      'api_settings': 'API设置',
      'select_api': '选择API',
      'clear_context': '清除上下文',
      'clear_messages': '清除消息',
      'add_attachment': '添加附件',
      'type_message': '输入消息',
      'no_messages': '暂无消息',
      'start_conversation': '开始对话',
      'copy_message': '复制消息',
      'message_copied': '消息已复制到剪贴板',
      'add_to_favorites': '添加到收藏',
      'remove_from_favorites': '从收藏中移除',
      'delete_message': '删除消息',
      'delete_config': '删除配置',
      'delete_confirm': '确定要删除吗？此操作无法撤消。',
      'cancel': '取消',
      'delete': '删除',
      'save': '保存',
      'edit': '编辑',
      'copy': '复制',
      'no_api_selected': '未选择API',
      'stop_generating': '停止生成',
      'continue_generating': '继续',
      'error': '错误',
      'unknown_error': '发生未知错误',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  static const List<Locale> supportedLocales = [
    Locale('zh'), // Chinese
    Locale('en'), // English
  ];
}
