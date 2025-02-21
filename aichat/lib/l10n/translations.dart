import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const List<Locale> supportedLocales = [
    Locale('zh'), // Chinese
    Locale('en'), // English
  ];

  static const AppLocalizationsDelegate delegate = AppLocalizationsDelegate();

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String getlang(String local , String key) {
    return _localizedValues[local]?[key] ?? key;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'AIChat',
      'chats': 'Chats',
      'settings': 'Settings',
      'profile': 'Profile',
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
      'loading': 'Loading...',
      'error_prefix': 'Error: ',
      'select_api_title': 'Select API',
      'clear_context_menu': 'Clear Context',
      'no_messages_title': 'No messages yet',
      'file_attachments_disabled': 'File attachments are temporarily disabled',
      'copy_api_config': 'Copy API Configuration',
      'add_api_config': 'Add API Configuration',
      'edit_api_config': 'Edit API Configuration',
      'api_name': 'Name',
      'api_name_hint': 'e.g., OpenAI API',
      'base_url': 'Base URL',
      'base_url_hint': 'e.g., https://api.openai.com',
      'api_key': 'API Key',
      'api_key_hint': 'Enter your API key',
      'default_model': 'Default Model',
      'default_model_hint': 'e.g., gpt-3.5-turbo',
      'no_api_configs': 'No API configurations found',
      'add_api_config_hint': 'Add an API configuration to get started',
      'new_chat': 'New Chat',
      'chat_title': 'Chat Title',
      'chat_title_hint': 'Enter a title for your chat',
      'create': 'Create',
      'no_chats': 'No chats yet',
      'start_new_chat': 'Start a new conversation',
      'search_in_chat': 'Search in chat',
      'search_chats_messages': 'Search chats and messages',
      'no_results': 'No results found',
      'try_different': 'Try different keywords',
      'message_in_chat': 'Message in {chatTitle}',
      'favorites': 'Favorites',
      'no_favorites': 'No favorites yet',
      'favorites_hint': 'Star messages or chats to save them here',
      'close': 'Close',
      'reasoning': 'Reasoning',
      'message_favorite_added': 'Message added to favorites',
      'message_favorite_removed': 'Message removed from favorites',
      'backup_restore': 'Backup & Restore',
      'export_data': 'Export Data',
      'export_data_desc': 'Save your chats and settings',
      'import_data': 'Import Data',
      'import_data_desc': 'Restore from backup',
      'import_warning':
          'Warning: Importing data will replace all existing chats, API configurations, and favorites.',
      'backup_settings': 'Backup Settings',
      'help_feedback': 'Help & Feedback',
      'about': 'About',
      'version': 'Version {version} ({buildNumber})',
      'loading_version': 'Loading...',
      'version_error': 'Error loading version info',
      'local_user': 'Local User',
      'local_storage': 'Using local storage',
      'context_split': 'Context Split',
      'no_messages_preview': 'No messages yet',
      'import_success': 'Data imported successfully',
      'proceed': 'Proceed',
      'no_backup_file': 'No backup file found',
      'invalid_backup_file': 'Invalid backup file format',
      'edit_title': 'Edit Title',
      'enter_title': 'Enter title',
      'theme': 'Theme',
      'language': 'Language',
      'choose_theme': 'Choose Theme',
      'choose_language': 'Choose Language',
      'api_settings_desc': 'Manage API endpoints and keys',
      'change_app_appearance': 'Change app appearance',
      'change_app_language': 'Change app language',
      'manage_api_endpoints_and_keys': 'Manage API endpoints and keys',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'english': 'English',
      'chinese': 'Chinese',
      'expanded_editor': 'Expanded Editor',
      'expand_editor': 'Expand Editor',
    },
    'zh': {
      'app_title': 'AI聊天',
      'chats': '聊天',
      'settings': '设置',
      'profile': '个人资料',
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
      'loading': '加载中...',
      'error_prefix': '错误：',
      'select_api_title': '选择API',
      'clear_context_menu': '清除上下文',
      'no_messages_title': '暂无消息',
      'file_attachments_disabled': '文件附件功能暂时禁用',
      'copy_api_config': '复制API配置',
      'add_api_config': '添加API配置',
      'edit_api_config': '编辑API配置',
      'api_name': '名称',
      'api_name_hint': '例如：OpenAI API',
      'base_url': '基础URL',
      'base_url_hint': '例如：https://api.openai.com',
      'api_key': 'API密钥',
      'api_key_hint': '输入您的API密钥',
      'default_model': '默认模型',
      'default_model_hint': '例如：gpt-3.5-turbo',
      'no_api_configs': '未找到API配置',
      'add_api_config_hint': '添加API配置以开始使用',
      'new_chat': '新建聊天',
      'chat_title': '聊天标题',
      'chat_title_hint': '输入聊天标题',
      'create': '创建',
      'no_chats': '暂无聊天',
      'start_new_chat': '开始新的对话',
      'search_in_chat': '在聊天中搜索',
      'search_chats_messages': '搜索聊天和消息',
      'no_results': '未找到结果',
      'try_different': '尝试使用其他关键词',
      'message_in_chat': '{chatTitle}中的消息',
      'favorites': '收藏',
      'no_favorites': '暂无收藏',
      'favorites_hint': '收藏消息或聊天将显示在这里',
      'close': '关闭',
      'reasoning': '推理',
      'message_favorite_added': '消息已添加到收藏',
      'message_favorite_removed': '消息已从收藏中移除',
      'backup_restore': '备份与恢复',
      'export_data': '导出数据',
      'export_data_desc': '保存您的聊天和设置',
      'import_data': '导入数据',
      'import_data_desc': '从备份中恢复',
      'import_warning': '警告：导入数据将替换所有现有的聊天、API配置和收藏。',
      'backup_settings': '备份设置',
      'help_feedback': '帮助与反馈',
      'about': '关于',
      'version': '版本 {version} ({buildNumber})',
      'loading_version': '加载中...',
      'version_error': '加载版本信息出错',
      'local_user': '本地用户',
      'local_storage': '使用本地存储',
      'context_split': '上下文分隔',
      'no_messages_preview': '暂无消息',
      'import_success': '数据导入成功',
      'proceed': '继续',
      'no_backup_file': '未找到备份文件',
      'invalid_backup_file': '备份文件格式无效',
      'edit_title': '编辑标题',
      'enter_title': '输入标题',
      'theme': '主题',
      'language': '语言',
      'choose_theme': '选择主题',
      'choose_language': '选择语言',
      'api_settings_desc': '管理API端点和密钥',
      'change_app_appearance': '更改应用外观',
      'change_app_language': '更改应用语言',
      'manage_api_endpoints_and_keys': '管理API端点和密钥',
      'system': '系统',
      'light': '亮色',
      'dark': '暗色',
      'english': '英语',
      'chinese': '中文',
      'expanded_editor': '扩展编辑器',
      'expand_editor': '展开编辑器',
    },
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
