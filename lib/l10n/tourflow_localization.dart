import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TourFlowLocaleController extends ChangeNotifier {
  TourFlowLocaleController._();

  static final TourFlowLocaleController instance = TourFlowLocaleController._();

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
    Locale('zh', 'CN'),
    Locale('ja'),
    Locale('ko'),
  ];

  String _languageCode = 'en';

  String get languageCode => _languageCode;
  Locale get locale => localeForCode(_languageCode);
  String get languageName => languageNameForCode(_languageCode);

  Future<void> loadForCurrentUser() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final row = await client
          .from('profiles')
          .select('preferred_language')
          .eq('id', user.id)
          .maybeSingle();
      useLanguageCode(row?['preferred_language']?.toString());
    } catch (_) {
      final metadata = user.userMetadata ?? const <String, dynamic>{};
      useLanguageCode(metadata['preferred_language']?.toString());
    }
  }

  void useLanguageCode(String? value) {
    final normalized = normalizeLanguageCode(value);
    if (_languageCode == normalized) return;
    _languageCode = normalized;
    notifyListeners();
  }

  Future<void> saveLanguageCode(String value) async {
    final normalized = normalizeLanguageCode(value);
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      throw const AuthException('Please sign in to change the app language.');
    }

    await client.rpc(
      'set_my_preferred_language',
      params: {'p_language': normalized},
    );
    useLanguageCode(normalized);
  }

  String translate(String english) {
    final source = english.replaceAll(r'\n', '\n');
    if (_languageCode == 'en' || source.isEmpty) return source;
    final exact = _translations[source];
    if (exact != null) return exact.forCode(_languageCode);
    return _translateTemplate(source);
  }

  String _translateTemplate(String source) {
    if (source.contains('\n')) {
      return source.split('\n').map(_translateTemplate).join('\n');
    }

    const rolePrefix = 'TOURFLOW · ';
    if (source.startsWith(rolePrefix)) {
      final rawRole = source.substring(rolePrefix.length).toLowerCase();
      final role = switch (rawRole) {
        'tourist' => 'Tourist',
        'operator' => 'Operator',
        'staff' => 'Staff',
        'administrator' || 'admin' => 'Administrator',
        _ => '',
      };
      if (role.isNotEmpty) {
        return '$rolePrefix${translate(role).toUpperCase()}';
      }
    }

    if (source.startsWith('Online · ')) {
      return '${translate('Online')} · ${translate(source.substring(9))}';
    }

    final colonIndex = source.indexOf(': ');
    if (colonIndex > 0) {
      final label = source.substring(0, colonIndex);
      final translatedLabel = _translations[label]?.forCode(_languageCode);
      if (translatedLabel != null) {
        final value = source.substring(colonIndex + 2);
        final translatedValue = label == 'Status' || label == 'Current status'
            ? _translations[value]?.forCode(_languageCode) ?? value
            : value;
        return '$translatedLabel: $translatedValue';
      }
    }

    final slotMatch = RegExp(r'^(\d+) slots?$').firstMatch(source);
    if (slotMatch != null) {
      final count = slotMatch.group(1)!;
      return switch (_languageCode) {
        'zh' => '$count 个时段',
        'ms' => '$count slot',
        'ja' => '$count件の時間枠',
        'ko' => '시간대 $count개',
        _ => source,
      };
    }

    return source;
  }

  static Locale localeForCode(String? value) =>
      switch (normalizeLanguageCode(value)) {
        'ms' => const Locale('ms'),
        'zh' => const Locale('zh', 'CN'),
        'ja' => const Locale('ja'),
        'ko' => const Locale('ko'),
        _ => const Locale('en'),
      };

  static String normalizeLanguageCode(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll('_', '-') ?? '';
    return switch (normalized) {
      'ms' || 'bm' || 'bahasa malaysia' || 'bahasa melayu' => 'ms',
      'zh' || 'zh-cn' || 'cn' || 'mandarin' || '中文' || '简体中文' => 'zh',
      'ja' || 'jp' || 'japanese' || '日本語' => 'ja',
      'ko' || 'kr' || 'korean' || '한국어' => 'ko',
      _ => 'en',
    };
  }

  static String languageNameForCode(String? value) =>
      switch (normalizeLanguageCode(value)) {
        'ms' => 'Bahasa Malaysia',
        'zh' => 'Mandarin',
        'ja' => 'Japanese',
        'ko' => 'Korean',
        _ => 'English',
      };
}

class TourFlowLanguageScope
    extends InheritedNotifier<TourFlowLocaleController> {
  const TourFlowLanguageScope({
    required TourFlowLocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static TourFlowLocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<TourFlowLanguageScope>();
    return scope?.notifier ?? TourFlowLocaleController.instance;
  }
}

extension TourFlowTranslationContext on BuildContext {
  String tr(String english) =>
      TourFlowLanguageScope.of(this).translate(english);
}

class TourFlowText extends StatelessWidget {
  const TourFlowText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      TourFlowLanguageScope.of(context).translate(data),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

class _Translation {
  const _Translation(this.ms, this.zh, this.ja, this.ko);

  final String ms;
  final String zh;
  final String ja;
  final String ko;

  String forCode(String code) => switch (code) {
    'ms' => ms,
    'zh' => zh,
    'ja' => ja,
    'ko' => ko,
    _ => '',
  };
}

const _translations = <String, _Translation>{
  'Home': _Translation('Utama', '首页', 'ホーム', '홈'),
  'Discover': _Translation('Teroka', '发现', '見つける', '둘러보기'),
  'Trips': _Translation('Perjalanan', '行程', '旅行', '여행'),
  'Chat': _Translation('Sembang', '聊天', 'チャット', '채팅'),
  'Profile': _Translation('Profil', '个人资料', 'プロフィール', '프로필'),
  'Dashboard': _Translation('Papan Pemuka', '仪表板', 'ダッシュボード', '대시보드'),
  'Attractions': _Translation('Tarikan', '景点', '観光地', '관광지'),
  'Slots': _Translation('Slot', '时段', '時間枠', '시간대'),
  'Reports': _Translation('Laporan', '报告', 'レポート', '보고서'),
  'Analytics': _Translation('Analitik', '分析', '分析', '분석'),
  'Reviews': _Translation('Semakan', '审核', '審査', '검토'),
  'Support': _Translation('Sokongan', '支持', 'サポート', '지원'),
  'Tourist': _Translation('Pelancong', '游客', '観光客', '관광객'),
  'Operator': _Translation('Pengendali', '营运商', '運営者', '운영자'),
  'Staff': _Translation('Kakitangan', '工作人员', 'スタッフ', '직원'),
  'Administrator': _Translation('Pentadbir', '管理员', '管理者', '관리자'),
  'Admin': _Translation('Pentadbir', '管理员', '管理者', '관리자'),
  'Operator Dashboard': _Translation(
    'Papan Pemuka Pengendali',
    '营运商仪表板',
    '運営者ダッシュボード',
    '운영자 대시보드',
  ),
  'Attraction Details': _Translation(
    'Butiran Tarikan',
    '景点详情',
    '観光地の詳細',
    '관광지 상세',
  ),
  'Attraction Review': _Translation(
    'Semakan Tarikan',
    '景点审核',
    '観光地の審査',
    '관광지 검토',
  ),
  'Slot Manager': _Translation('Pengurus Slot', '时段管理', '時間枠管理', '시간대 관리'),
  'Support Tickets': _Translation(
    'Tiket Sokongan',
    '支持工单',
    'サポートチケット',
    '지원 티켓',
  ),
  'Support Ticket Details': _Translation(
    'Butiran Tiket Sokongan',
    '支持工单详情',
    'サポートチケット詳細',
    '지원 티켓 상세',
  ),
  'Ticket Details': _Translation('Butiran Tiket', '工单详情', 'チケット詳細', '티켓 상세'),
  'Scan QR': _Translation('Imbas QR', '扫描二维码', 'QRをスキャン', 'QR 스캔'),
  'Discover Attractions': _Translation(
    'Teroka Tarikan',
    '发现景点',
    '観光地を探す',
    '관광지 둘러보기',
  ),
  'My Trips & Bookings': _Translation(
    'Perjalanan & Tempahan Saya',
    '我的行程与预订',
    '旅行と予約',
    '내 여행 및 예약',
  ),
  'My Trips': _Translation('Perjalanan Saya', '我的行程', '旅行', '내 여행'),
  'Itinerary Planner': _Translation(
    'Perancang Jadual',
    '行程规划',
    '旅程プランナー',
    '여행 일정 플래너',
  ),
  'Chatbot & Support': _Translation(
    'Chatbot & Sokongan',
    '聊天机器人与支持',
    'チャットボットとサポート',
    '챗봇 및 지원',
  ),
  'Feedback': _Translation('Maklum Balas', '反馈', 'フィードバック', '피드백'),
  'My Profile': _Translation('Profil Saya', '我的个人资料', 'プロフィール', '내 프로필'),
  'Profile and Security': _Translation(
    'Profil dan Keselamatan',
    '个人资料与安全',
    'プロフィールとセキュリティ',
    '프로필 및 보안',
  ),
  'Language Settings': _Translation('Tetapan Bahasa', '语言设置', '言語設定', '언어 설정'),
  'Chat History': _Translation('Sejarah Sembang', '聊天记录', 'チャット履歴', '채팅 기록'),
  'Chat history': _Translation('Sejarah sembang', '聊天记录', 'チャット履歴', '채팅 기록'),
  'Back': _Translation('Kembali', '返回', '戻る', '뒤로'),
  'Open menu': _Translation('Buka menu', '打开菜单', 'メニューを開く', '메뉴 열기'),
  'Log Out': _Translation('Log Keluar', '退出登录', 'ログアウト', '로그아웃'),
  'Save': _Translation('Simpan', '保存', '保存', '저장'),
  'Saving...': _Translation('Menyimpan...', '保存中……', '保存中…', '저장 중...'),
  'Cancel': _Translation('Batal', '取消', 'キャンセル', '취소'),
  'Delete': _Translation('Padam', '删除', '削除', '삭제'),
  'Edit': _Translation('Edit', '编辑', '編集', '편집'),
  'View': _Translation('Lihat', '查看', '表示', '보기'),
  'View all': _Translation('Lihat semua', '查看全部', 'すべて表示', '모두 보기'),
  'Retry': _Translation('Cuba Lagi', '重试', '再試行', '다시 시도'),
  'Try Again': _Translation('Cuba Lagi', '重试', '再試行', '다시 시도'),
  'Try again': _Translation('Cuba lagi', '重试', '再試行', '다시 시도'),
  'Refresh': _Translation('Muat Semula', '刷新', '更新', '새로고침'),
  'Close': _Translation('Tutup', '关闭', '閉じる', '닫기'),
  'Done': _Translation('Selesai', '完成', '完了', '완료'),
  'New': _Translation('Baharu', '新建', '新規', '새로 만들기'),
  'Remove': _Translation('Buang', '移除', '削除', '제거'),
  'Search': _Translation('Cari', '搜索', '検索', '검색'),
  'Filter': _Translation('Tapis', '筛选', '絞り込み', '필터'),
  'Apply filters': _Translation('Gunakan penapis', '应用筛选', '絞り込みを適用', '필터 적용'),
  'Browse': _Translation('Lihat', '浏览', '閲覧', '둘러보기'),
  'Details': _Translation('Butiran', '详情', '詳細', '상세'),
  'Status': _Translation('Status', '状态', 'ステータス', '상태'),
  'Current status': _Translation('Status semasa', '当前状态', '現在のステータス', '현재 상태'),
  'Ticket ID': _Translation('ID Tiket', '工单编号', 'チケットID', '티켓 ID'),
  'Pending': _Translation('Menunggu', '待处理', '保留中', '대기 중'),
  'In Progress': _Translation('Sedang Diproses', '处理中', '対応中', '처리 중'),
  'In progress': _Translation('Sedang diproses', '处理中', '対応中', '처리 중'),
  'Resolved': _Translation('Selesai', '已解决', '解決済み', '해결됨'),
  'Low': _Translation('Rendah', '低', '低い', '낮음'),
  'Moderate': _Translation('Sederhana', '中等', '普通', '보통'),
  'High': _Translation('Tinggi', '高', '高い', '높음'),
  'English': _Translation('Bahasa Inggeris', '英语', '英語', '영어'),
  'Bahasa Malaysia': _Translation('Bahasa Malaysia', '马来语', 'マレー語', '말레이어'),
  'Mandarin': _Translation('Bahasa Mandarin', '简体中文', '中国語', '중국어'),
  'Japanese': _Translation('Bahasa Jepun', '日语', '日本語', '일본어'),
  'Korean': _Translation('Bahasa Korea', '韩语', '韓国語', '한국어'),
  'Quick actions': _Translation('Tindakan pantas', '快捷操作', 'クイック操作', '빠른 작업'),
  'Use the guided options above...': _Translation(
    'Gunakan pilihan berpandu di atas...',
    '请使用上方的引导选项……',
    '上のガイド付き選択肢を使用してください…',
    '위의 안내 선택지를 사용하세요...',
  ),
  'Ask TourFlow anything...': _Translation(
    'Tanya apa-apa tentang TourFlow...',
    '询问任何 TourFlow 相关问题……',
    'TourFlowについて質問してください…',
    'TourFlow에 대해 무엇이든 물어보세요...',
  ),
  'Popular in Kuala Lumpur': _Translation(
    'Popular di Kuala Lumpur',
    '吉隆坡热门景点',
    'クアラルンプールで人気',
    '쿠알라룸푸르 인기 명소',
  ),
  'Recommended for You': _Translation(
    'Disyorkan untuk Anda',
    '为你推荐',
    'おすすめ',
    '추천',
  ),
  'Available slots': _Translation(
    'Slot tersedia',
    '可用时段',
    '利用可能な時間枠',
    '예약 가능 시간대',
  ),
  'Available time slots': _Translation(
    'Slot masa tersedia',
    '可用时间段',
    '利用可能な時間枠',
    '예약 가능 시간대',
  ),
  'Opening hours': _Translation('Waktu operasi', '开放时间', '営業時間', '운영 시간'),
  'Facilities': _Translation('Kemudahan', '设施', '設備', '시설'),
  'Operating Hours': _Translation('Waktu Operasi', '开放时间', '営業時間', '운영 시간'),
  'Operating hours': _Translation('Waktu operasi', '开放时间', '営業時間', '운영 시간'),
  'Attachments': _Translation('Lampiran', '附件', '添付ファイル', '첨부 파일'),
  'Complaint photos': _Translation('Foto aduan', '投诉照片', '苦情の写真', '불만 사진'),
  'Complaint details': _Translation('Butiran aduan', '投诉详情', '苦情の詳細', '불만 상세'),
  'My support tickets': _Translation(
    'Tiket sokongan saya',
    '我的支持工单',
    '自分のサポートチケット',
    '내 지원 티켓',
  ),
  'Create Support Ticket': _Translation(
    'Cipta Tiket Sokongan',
    '建立支持工单',
    'サポートチケットを作成',
    '지원 티켓 만들기',
  ),
  'Create Ticket': _Translation('Cipta Tiket', '建立工单', 'チケットを作成', '티켓 만들기'),
  'View Tickets': _Translation('Lihat Tiket', '查看工单', 'チケットを表示', '티켓 보기'),
  'Reply to tourist': _Translation(
    'Balas kepada pelancong',
    '回复游客',
    '観光客に返信',
    '관광객에게 답변',
  ),
  'Send Response': _Translation('Hantar Respons', '发送回复', '返信を送信', '답변 보내기'),
  'Save Status': _Translation('Simpan Status', '保存状态', 'ステータスを保存', '상태 저장'),
  'Refresh live data': _Translation(
    'Muat semula data langsung',
    '刷新实时数据',
    'ライブデータを更新',
    '실시간 데이터 새로고침',
  ),
  'Current Crowd Level': _Translation(
    'Tahap Kesesakan Semasa',
    '当前人流情况',
    '現在の混雑状況',
    '현재 혼잡도',
  ),
  'Current Visitors': _Translation(
    'Pelawat Semasa',
    '当前游客人数',
    '現在の来場者',
    '현재 방문객',
  ),
  'Near me': _Translation('Berdekatan saya', '我附近', '現在地周辺', '내 주변'),
  'Discovery filters': _Translation(
    'Penapis carian',
    '发现筛选',
    '検索フィルター',
    '검색 필터',
  ),
  'Any crowd level': _Translation(
    'Semua tahap kesesakan',
    '任何拥挤程度',
    'すべての混雑度',
    '모든 혼잡도',
  ),
  'Any distance': _Translation('Semua jarak', '任何距离', 'すべての距離', '모든 거리'),
  'Any price': _Translation('Semua harga', '任何价格', 'すべての価格', '모든 가격'),
  'Compare Attractions': _Translation(
    'Bandingkan Tarikan',
    '比较景点',
    '観光地を比較',
    '관광지 비교',
  ),
  'Plan itinerary': _Translation('Rancang jadual', '规划行程', '旅程を計画', '일정 계획'),
  'Number of visitors': _Translation(
    'Bilangan pelawat',
    '游客人数',
    '訪問者数',
    '방문객 수',
  ),
  'Booking Details': _Translation('Butiran Tempahan', '预订详情', '予約詳細', '예약 상세'),
  'Booking QR Code': _Translation(
    'Kod QR Tempahan',
    '预订二维码',
    '予約QRコード',
    '예약 QR 코드',
  ),
  'View QR Code': _Translation('Lihat Kod QR', '查看二维码', 'QRコードを表示', 'QR 코드 보기'),
  'Cancel booking': _Translation(
    'Batalkan tempahan',
    '取消预订',
    '予約をキャンセル',
    '예약 취소',
  ),
  'Reschedule': _Translation('Jadual Semula', '重新安排', '日程変更', '일정 변경'),
  'Reschedule Booking': _Translation(
    'Jadual Semula Tempahan',
    '重新安排预订',
    '予約日程を変更',
    '예약 일정 변경',
  ),
  'Change Password': _Translation(
    'Tukar Kata Laluan',
    '修改密码',
    'パスワード変更',
    '비밀번호 변경',
  ),
  'Reset Password Link': _Translation(
    'Pautan Tetap Semula Kata Laluan',
    '重置密码链接',
    'パスワード再設定リンク',
    '비밀번호 재설정 링크',
  ),
  'Update Password': _Translation(
    'Kemas Kini Kata Laluan',
    '更新密码',
    'パスワードを更新',
    '비밀번호 업데이트',
  ),
  'Security': _Translation('Keselamatan', '安全', 'セキュリティ', '보안'),
  'TourFlow Assistant': _Translation(
    'Pembantu TourFlow',
    'TourFlow 助手',
    'TourFlowアシスタント',
    'TourFlow 도우미',
  ),
  'Online': _Translation('Dalam talian', '在线', 'オンライン', '온라인'),
  'Start a conversation': _Translation(
    'Mulakan perbualan',
    '开始对话',
    '会話を始める',
    '대화 시작',
  ),
  'Need attraction suggestions?': _Translation(
    'Perlukan cadangan tarikan?',
    '需要景点推荐吗？',
    '観光地の提案が必要ですか？',
    '관광지 추천이 필요하신가요?',
  ),
  'Still need help? Create a support ticket': _Translation(
    'Masih perlukan bantuan? Cipta tiket sokongan',
    '仍需要帮助？建立支持工单',
    'さらにサポートが必要ですか？チケットを作成',
    '도움이 더 필요하신가요? 지원 티켓 만들기',
  ),
  'Confirm your complaint': _Translation(
    'Sahkan aduan anda',
    '确认你的投诉',
    '苦情を確認',
    '불만 내용 확인',
  ),
  'Complaint submitted': _Translation(
    'Aduan dihantar',
    '投诉已提交',
    '苦情を送信しました',
    '불만이 제출되었습니다',
  ),
  'Submit Complaint': _Translation('Hantar Aduan', '提交投诉', '苦情を送信', '불만 제출'),
  'Submitting…': _Translation('Menghantar…', '提交中……', '送信中…', '제출 중…'),
  'Cancel Draft': _Translation('Batalkan Draf', '取消草稿', '下書きを破棄', '초안 취소'),
  'Start Over': _Translation('Mula Semula', '重新开始', '最初からやり直す', '다시 시작'),
  'Continue Without Photo': _Translation(
    'Teruskan Tanpa Foto',
    '不上传照片并继续',
    '写真なしで続行',
    '사진 없이 계속',
  ),
  'Attraction': _Translation('Tarikan', '景点', '観光地', '관광지'),
  'Booking': _Translation('Tempahan', '预订', '予約', '예약'),
  'Photo': _Translation('Foto', '照片', '写真', '사진'),
  'Not selected': _Translation('Belum dipilih', '尚未选择', '未選択', '선택되지 않음'),
  'Photo requested — please select one': _Translation(
    'Foto diperlukan — sila pilih satu',
    '需要照片——请选择一张',
    '写真が必要です—選択してください',
    '사진이 필요합니다—한 장 선택하세요',
  ),
  'No photo required': _Translation(
    'Foto tidak diperlukan',
    '不需要照片',
    '写真は不要です',
    '사진 필요 없음',
  ),
  'Choose Photo': _Translation('Pilih Foto', '选择照片', '写真を選択', '사진 선택'),
  'Change Photo': _Translation('Tukar Foto', '更换照片', '写真を変更', '사진 변경'),
  'Nothing is submitted until you press the button below.': _Translation(
    'Tiada apa-apa dihantar sehingga anda menekan butang di bawah.',
    '在你按下下方按钮之前，不会提交任何内容。',
    '下のボタンを押すまで送信されません。',
    '아래 버튼을 누르기 전에는 아무 내용도 제출되지 않습니다.',
  ),
  'Preferred app language': _Translation(
    'Bahasa aplikasi pilihan',
    '首选应用语言',
    '優先するアプリ言語',
    '기본 앱 언어',
  ),
  'Save Language': _Translation('Simpan Bahasa', '保存语言', '言語を保存', '언어 저장'),
  'The selected language applies to the whole TourFlow app, including navigation, pages, system messages and the chatbot. Attraction names, addresses, booking codes and user-written content remain unchanged.':
      _Translation(
        'Bahasa yang dipilih digunakan untuk seluruh aplikasi TourFlow, termasuk navigasi, halaman, mesej sistem dan chatbot. Nama tarikan, alamat, kod tempahan dan kandungan pengguna tidak berubah.',
        '所选语言会应用于整个 TourFlow，包括导航、页面、系统信息和聊天机器人。景点名称、地址、预订编号和用户输入内容保持不变。',
        '選択した言語は、ナビゲーション、各ページ、システムメッセージ、チャットボットを含むTourFlow全体に適用されます。観光地名、住所、予約コード、ユーザー入力は変更されません。',
        '선택한 언어는 탐색 메뉴, 페이지, 시스템 메시지 및 챗봇을 포함한 TourFlow 전체에 적용됩니다. 관광지 이름, 주소, 예약 코드와 사용자가 작성한 내용은 변경되지 않습니다.',
      ),
  'App language updated.': _Translation(
    'Bahasa aplikasi dikemas kini.',
    '应用语言已更新。',
    'アプリの言語を更新しました。',
    '앱 언어가 업데이트되었습니다.',
  ),
  'Navigation, pages, system messages and the chatbot will use the same language.':
      _Translation(
        'Navigasi, halaman, mesej sistem dan chatbot akan menggunakan bahasa yang sama.',
        '导航、页面、系统信息和聊天机器人将使用同一种语言。',
        'ナビゲーション、各ページ、システムメッセージ、チャットボットで同じ言語を使用します。',
        '탐색 메뉴, 페이지, 시스템 메시지 및 챗봇이 같은 언어를 사용합니다.',
      ),
  'Welcome to TourFlow': _Translation(
    'Selamat datang ke TourFlow',
    '欢迎使用 TourFlow',
    'TourFlowへようこそ',
    'TourFlow에 오신 것을 환영합니다',
  ),
  'Access your personalised dashboard and manage\nyour travel experience efficiently.':
      _Translation(
        'Akses papan pemuka peribadi dan urus\npengalaman perjalanan anda dengan mudah.',
        '进入个性化仪表板，高效管理\n你的旅行体验。',
        '個人用ダッシュボードから\n旅行体験を効率よく管理できます。',
        '개인 대시보드에서\n여행 경험을 효율적으로 관리하세요.',
      ),
  'Account Type': _Translation('Jenis Akaun', '账户类型', 'アカウント種類', '계정 유형'),
  'Context-Aware Interface': _Translation(
    'Antara Muka Mengikut Konteks',
    '情境感知界面',
    '状況対応インターフェース',
    '상황 인식 인터페이스',
  ),
  'Available menus and navigation depend on your selected role and clearance level.':
      _Translation(
        'Menu dan navigasi bergantung pada peranan serta tahap akses anda.',
        '可用菜单和导航取决于你选择的角色和权限级别。',
        '利用できるメニューは役割と権限レベルによって変わります。',
        '사용 가능한 메뉴와 탐색은 선택한 역할과 권한 수준에 따라 달라집니다.',
      ),
  'Forgot Password?': _Translation(
    'Lupa Kata Laluan?',
    '忘记密码？',
    'パスワードをお忘れですか？',
    '비밀번호를 잊으셨나요?',
  ),
  'Sign In': _Translation('Log Masuk', '登录', 'ログイン', '로그인'),
  'Signing In...': _Translation(
    'Sedang Log Masuk...',
    '正在登录……',
    'ログイン中…',
    '로그인 중...',
  ),
  'Sign Up': _Translation('Daftar', '注册', '新規登録', '회원가입'),
  'NEW TO TOURFLOW?': _Translation(
    'BARU MENGGUNAKAN TOURFLOW?',
    '第一次使用 TOURFLOW？',
    'TOURFLOWは初めてですか？',
    'TOURFLOW가 처음이신가요?',
  ),
  'Already have an account? Sign In': _Translation(
    'Sudah mempunyai akaun? Log Masuk',
    '已有账户？立即登录',
    'アカウントをお持ちですか？ログイン',
    '이미 계정이 있으신가요? 로그인',
  ),
  'Continue to Sign In': _Translation(
    'Teruskan ke Log Masuk',
    '前往登录',
    'ログインへ進む',
    '로그인으로 계속',
  ),
  'Staff and administrator accounts are provisioned by an administrator.':
      _Translation(
        'Akaun kakitangan dan pentadbir disediakan oleh pentadbir.',
        '工作人员和管理员账户由管理员建立。',
        'スタッフと管理者のアカウントは管理者が作成します。',
        '직원 및 관리자 계정은 관리자가 생성합니다.',
      ),
  'Account Created': _Translation(
    'Akaun Dicipta',
    '账户已建立',
    'アカウントを作成しました',
    '계정이 생성되었습니다',
  ),
  'You are registered!': _Translation(
    'Pendaftaran berjaya!',
    '注册成功！',
    '登録が完了しました！',
    '가입이 완료되었습니다!',
  ),
  'Your tourist account is ready. Sign in to start planning visits.':
      _Translation(
        'Akaun pelancong anda sedia. Log masuk untuk mula merancang lawatan.',
        '游客账户已准备好。登录后即可开始规划行程。',
        '観光客アカウントの準備ができました。ログインして計画を始めましょう。',
        '관광객 계정이 준비되었습니다. 로그인하여 방문 계획을 시작하세요.',
      ),
  'Good morning, Alex': _Translation(
    'Selamat pagi, Alex',
    '早上好，Alex',
    'おはようございます、Alex',
    '좋은 아침입니다, Alex',
  ),
  'Browse available attractions and time slots.': _Translation(
    'Lihat tarikan dan slot masa yang tersedia.',
    '浏览可用景点和时间段。',
    '利用可能な観光地と時間枠を確認します。',
    '이용 가능한 관광지와 시간대를 둘러보세요.',
  ),
  'Ratings, feedback and issue reports': _Translation(
    'Penilaian, maklum balas dan laporan isu',
    '评分、反馈和问题报告',
    '評価、フィードバック、問題報告',
    '평점, 피드백 및 문제 신고',
  ),
  'Live visitor counts will come from Module 4. Ratings are not fabricated.':
      _Translation(
        'Jumlah pelawat langsung datang daripada Modul 4. Penilaian tidak direka.',
        '实时游客人数来自模块 4，评分不会被虚构。',
        '来場者数はモジュール4から取得し、評価は作成しません。',
        '실시간 방문객 수는 모듈 4에서 제공되며 평점은 임의로 생성하지 않습니다.',
      ),
  'CROWD LEVEL GUIDE': _Translation(
    'PANDUAN TAHAP KESESAKAN',
    '人流等级说明',
    '混雑度ガイド',
    '혼잡도 안내',
  ),
  'Crowd labels are slot occupancy estimates': _Translation(
    'Label kesesakan ialah anggaran penggunaan slot',
    '人流标签是时段占用率估算',
    '混雑表示は時間枠の使用率推定です',
    '혼잡도 표시는 시간대 점유율 추정치입니다',
  ),
  'Module 2 demo mode': _Translation(
    'Mod demo Modul 2',
    '模块 2 演示模式',
    'モジュール2デモモード',
    '모듈 2 데모 모드',
  ),
  'No login is required. Preference changes last until the app restarts.':
      _Translation(
        'Log masuk tidak diperlukan. Pilihan kekal sehingga aplikasi dimulakan semula.',
        '无需登录。偏好设置会保留到应用重新启动。',
        'ログインは不要です。設定はアプリを再起動するまで保持されます。',
        '로그인이 필요하지 않습니다. 설정은 앱을 다시 시작할 때까지 유지됩니다.',
      ),
  'Discovery Preferences': _Translation(
    'Pilihan Carian',
    '发现偏好',
    '検索設定',
    '검색 환경설정',
  ),
  'Discovery preferences saved.': _Translation(
    'Pilihan carian disimpan.',
    '发现偏好已保存。',
    '検索設定を保存しました。',
    '검색 환경설정이 저장되었습니다.',
  ),
  'Search Kuala Lumpur attractions...': _Translation(
    'Cari tarikan di Kuala Lumpur...',
    '搜索吉隆坡景点……',
    'クアラルンプールの観光地を検索…',
    '쿠알라룸푸르 관광지 검색...',
  ),
  'Compare up to three attractions.': _Translation(
    'Bandingkan sehingga tiga tarikan.',
    '最多比较三个景点。',
    '最大3か所の観光地を比較できます。',
    '최대 3개의 관광지를 비교하세요.',
  ),
  'No approved attractions match these filters.': _Translation(
    'Tiada tarikan yang diluluskan sepadan dengan penapis ini.',
    '没有符合这些筛选条件的已审核景点。',
    '条件に一致する承認済み観光地はありません。',
    '이 필터와 일치하는 승인된 관광지가 없습니다.',
  ),
  'Could not load approved attractions.': _Translation(
    'Tarikan yang diluluskan tidak dapat dimuatkan.',
    '无法加载已审核景点。',
    '承認済み観光地を読み込めませんでした。',
    '승인된 관광지를 불러올 수 없습니다.',
  ),
  'No ratings yet': _Translation(
    'Belum ada penilaian',
    '暂无评分',
    '評価はまだありません',
    '아직 평점이 없습니다',
  ),
  'Open now': _Translation('Dibuka sekarang', '现在开放', '営業中', '현재 운영 중'),
  'Indoor': _Translation('Dalaman', '室内', '屋内', '실내'),
  'Outdoor': _Translation('Luaran', '室外', '屋外', '야외'),
  'Interests': _Translation('Minat', '兴趣', '興味', '관심사'),
  'Required facilities': _Translation(
    'Kemudahan diperlukan',
    '所需设施',
    '必要な設備',
    '필수 시설',
  ),
  'Set preferences': _Translation('Tetapkan pilihan', '设置偏好', '設定する', '환경설정'),
  'Smart Recommendations': _Translation(
    'Cadangan Pintar',
    '智能推荐',
    'スマートおすすめ',
    '스마트 추천',
  ),
  'Explainable matches': _Translation(
    'Padanan yang boleh dijelaskan',
    '可解释匹配',
    '理由が分かる候補',
    '설명 가능한 추천',
  ),
  'Scores use preferences, distance, slot availability, estimated crowd and completed visits.':
      _Translation(
        'Skor menggunakan pilihan, jarak, ketersediaan slot, anggaran kesesakan dan lawatan selesai.',
        '评分依据偏好、距离、可用时段、预计人流和已完成行程。',
        'スコアは設定、距離、空き時間枠、混雑予測、訪問履歴に基づきます。',
        '점수는 환경설정, 거리, 시간대 가용성, 예상 혼잡도 및 완료된 방문을 반영합니다.',
      ),
  'Nearby Attractions': _Translation(
    'Tarikan Berdekatan',
    '附近景点',
    '周辺の観光地',
    '주변 관광지',
  ),
  'Location permission was unavailable, so TourFlow is using its Kuala Lumpur demo origin.':
      _Translation(
        'Kebenaran lokasi tidak tersedia, jadi TourFlow menggunakan lokasi demo Kuala Lumpur.',
        '无法取得定位权限，因此 TourFlow 使用吉隆坡演示位置。',
        '位置情報を取得できないため、クアラルンプールのデモ位置を使用します。',
        '위치 권한을 사용할 수 없어 쿠알라룸푸르 데모 위치를 사용합니다.',
      ),
  'No nearby attraction has a suitable available slot yet.': _Translation(
    'Belum ada tarikan berdekatan dengan slot yang sesuai.',
    '附近景点暂时没有合适的可用时段。',
    '周辺に適切な空き時間枠のある観光地はありません。',
    '주변 관광지에 적절한 이용 가능 시간대가 없습니다.',
  ),
  'My Bookings': _Translation('Tempahan Saya', '我的预订', '予約', '내 예약'),
  'No bookings in this section.': _Translation(
    'Tiada tempahan dalam bahagian ini.',
    '此部分没有预订。',
    'このセクションに予約はありません。',
    '이 섹션에 예약이 없습니다.',
  ),
  'Could not load your bookings.': _Translation(
    'Tempahan anda tidak dapat dimuatkan.',
    '无法加载你的预订。',
    '予約を読み込めませんでした。',
    '예약을 불러올 수 없습니다.',
  ),
  'Booking Confirmed': _Translation(
    'Tempahan Disahkan',
    '预订已确认',
    '予約確定',
    '예약 확정',
  ),
  'Confirm Booking': _Translation('Sahkan Tempahan', '确认预订', '予約を確定', '예약 확인'),
  'Review Booking': _Translation('Semak Tempahan', '检查预订', '予約を確認', '예약 검토'),
  'Choose a Visit Slot': _Translation(
    'Pilih Slot Lawatan',
    '选择参观时段',
    '訪問時間枠を選択',
    '방문 시간대 선택',
  ),
  'Choose your visit date': _Translation(
    'Pilih tarikh lawatan',
    '选择参观日期',
    '訪問日を選択',
    '방문 날짜 선택',
  ),
  'Select a Time Slot': _Translation(
    'Pilih Slot Masa',
    '选择时间段',
    '時間枠を選択',
    '시간대 선택',
  ),
  'Please arrive 10 minutes early.': _Translation(
    'Sila tiba 10 minit lebih awal.',
    '请提前 10 分钟到达。',
    '10分前にお越しください。',
    '10분 일찍 도착해 주세요.',
  ),
  'Present this code at check-in. Each booking can only be checked in once.':
      _Translation(
        'Tunjukkan kod ini semasa daftar masuk. Setiap tempahan hanya boleh didaftar masuk sekali.',
        '签到时请出示此二维码。每项预订只能签到一次。',
        'チェックイン時にこのコードを提示してください。各予約は1回のみ使用できます。',
        '체크인 시 이 코드를 제시하세요. 각 예약은 한 번만 체크인할 수 있습니다.',
      ),
  'Cancel booking?': _Translation(
    'Batalkan tempahan?',
    '取消预订？',
    '予約をキャンセルしますか？',
    '예약을 취소하시겠습니까?',
  ),
  'Keep booking': _Translation('Kekalkan tempahan', '保留预订', '予約を維持', '예약 유지'),
  'The reserved spaces will be released immediately. This cannot be undone.':
      _Translation(
        'Tempat tempahan akan dilepaskan serta-merta. Tindakan ini tidak boleh dibatalkan.',
        '预留名额将立即释放，且无法撤销。',
        '予約枠は直ちに解放され、元に戻せません。',
        '예약된 자리는 즉시 해제되며 되돌릴 수 없습니다.',
      ),
  'Booking rescheduled. Old capacity was released.': _Translation(
    'Tempahan dijadualkan semula. Kapasiti lama telah dilepaskan.',
    '预订已重新安排，原名额已释放。',
    '予約を変更し、以前の枠を解放しました。',
    '예약 일정이 변경되었고 기존 자리는 해제되었습니다.',
  ),
  'Choose confirmed bookings': _Translation(
    'Pilih tempahan yang disahkan',
    '选择已确认的预订',
    '確定済み予約を選択',
    '확정된 예약 선택',
  ),
  'Add to itinerary': _Translation(
    'Tambah ke jadual',
    '添加到行程',
    '旅程に追加',
    '일정에 추가',
  ),
  'Itinerary saved.': _Translation(
    'Jadual disimpan.',
    '行程已保存。',
    '旅程を保存しました。',
    '일정이 저장되었습니다.',
  ),
  'Enter an itinerary name.': _Translation(
    'Masukkan nama jadual.',
    '请输入行程名称。',
    '旅程名を入力してください。',
    '일정 이름을 입력하세요.',
  ),
  'Create an upcoming booking before building an itinerary.': _Translation(
    'Buat tempahan akan datang sebelum membina jadual.',
    '建立行程前，请先创建即将到来的预订。',
    '旅程を作る前に今後の予約を作成してください。',
    '일정을 만들기 전에 예정된 예약을 생성하세요.',
  ),
  'Chatbot Scope': _Translation(
    'Skop Chatbot',
    '聊天机器人范围',
    'チャットボットの範囲',
    '챗봇 범위',
  ),
  'Ask for general TourFlow guidance. Check the relevant page for verified bookings, availability, prices, and live crowd data.':
      _Translation(
        'Tanya panduan TourFlow umum. Semak halaman berkaitan untuk tempahan, ketersediaan, harga dan data kesesakan yang disahkan.',
        '可以询问 TourFlow 的一般使用方法。预订、可用名额、价格和实时人流请以相关页面为准。',
        'TourFlowの一般的な使い方を質問できます。予約、空き状況、価格、混雑データは各ページで確認してください。',
        'TourFlow 일반 사용법을 물어볼 수 있습니다. 확인된 예약, 가용성, 가격 및 실시간 혼잡도는 관련 페이지에서 확인하세요.',
      ),
  'Conversation deleted.': _Translation(
    'Perbualan dipadam.',
    '对话已删除。',
    '会話を削除しました。',
    '대화가 삭제되었습니다.',
  ),
  'Delete conversation?': _Translation(
    'Padam perbualan?',
    '删除对话？',
    '会話を削除しますか？',
    '대화를 삭제하시겠습니까?',
  ),
  'The previous conversation was deleted. A new conversation has been started.':
      _Translation(
        'Perbualan sebelumnya dipadam. Perbualan baharu dimulakan.',
        '之前的对话已删除，现已开始新对话。',
        '以前の会話を削除し、新しい会話を開始しました。',
        '이전 대화가 삭제되고 새 대화가 시작되었습니다.',
      ),
  'Profile saved.': _Translation(
    'Profil disimpan.',
    '个人资料已保存。',
    'プロフィールを保存しました。',
    '프로필이 저장되었습니다.',
  ),
  'Verify your current password before choosing a new one': _Translation(
    'Sahkan kata laluan semasa sebelum memilih kata laluan baharu',
    '设置新密码前，请先验证当前密码',
    '新しいパスワードを設定する前に現在のパスワードを確認します',
    '새 비밀번호를 설정하기 전에 현재 비밀번호를 확인하세요',
  ),
  'Feedback Centre': _Translation(
    'Pusat Maklum Balas',
    '反馈中心',
    'フィードバックセンター',
    '피드백 센터',
  ),
  'How was your visit?': _Translation(
    'Bagaimanakah lawatan anda?',
    '你的参观体验如何？',
    '訪問はいかがでしたか？',
    '방문은 어떠셨나요?',
  ),
  'What did you like most?': _Translation(
    'Apakah yang paling anda sukai?',
    '你最喜欢什么？',
    '最も良かった点は何ですか？',
    '가장 좋았던 점은 무엇인가요?',
  ),
  'Your feedback improves crowd planning and attraction quality.': _Translation(
    'Maklum balas anda membantu perancangan kesesakan dan kualiti tarikan.',
    '你的反馈有助于改善人流规划和景点质量。',
    'フィードバックは混雑計画と観光地の品質向上に役立ちます。',
    '피드백은 혼잡 관리와 관광지 품질 개선에 도움이 됩니다.',
  ),
  'No feedback submitted yet.': _Translation(
    'Belum ada maklum balas dihantar.',
    '尚未提交反馈。',
    '送信済みフィードバックはありません。',
    '아직 제출된 피드백이 없습니다.',
  ),
  'Report Issue': _Translation('Laporkan Isu', '报告问题', '問題を報告', '문제 신고'),
  'Report an Issue': _Translation('Laporkan Isu', '报告问题', '問題を報告', '문제 신고'),
  'No issue reports submitted yet.': _Translation(
    'Belum ada laporan isu dihantar.',
    '尚未提交问题报告。',
    '送信済みの問題報告はありません。',
    '아직 제출된 문제 신고가 없습니다.',
  ),
  'Track your reports': _Translation(
    'Jejak laporan anda',
    '追踪你的报告',
    '報告を追跡',
    '신고 추적',
  ),
  'No support tickets found.': _Translation(
    'Tiada tiket sokongan ditemui.',
    '未找到支持工单。',
    'サポートチケットがありません。',
    '지원 티켓을 찾을 수 없습니다.',
  ),
  'No activity has been recorded yet.': _Translation(
    'Belum ada aktiviti direkodkan.',
    '尚未记录任何处理活动。',
    '記録されたアクティビティはありません。',
    '아직 기록된 활동이 없습니다.',
  ),
  'No related booking': _Translation(
    'Tiada tempahan berkaitan',
    '没有相关预订',
    '関連予約なし',
    '관련 예약 없음',
  ),
  'Support ticket submitted': _Translation(
    'Tiket sokongan dihantar',
    '支持工单已提交',
    'サポートチケットを送信しました',
    '지원 티켓이 제출되었습니다',
  ),
  'Scan Tourist QR Code': _Translation(
    'Imbas Kod QR Pelancong',
    '扫描游客二维码',
    '観光客のQRコードをスキャン',
    '관광객 QR 코드 스캔',
  ),
  'Visitor Check-In': _Translation(
    'Daftar Masuk Pelawat',
    '游客签到',
    '来場者チェックイン',
    '방문객 체크인',
  ),
  'Confirm Check-In': _Translation(
    'Sahkan Daftar Masuk',
    '确认签到',
    'チェックインを確定',
    '체크인 확인',
  ),
  'Check-In Successful': _Translation(
    'Daftar Masuk Berjaya',
    '签到成功',
    'チェックイン成功',
    '체크인 성공',
  ),
  'Open Camera': _Translation('Buka Kamera', '打开相机', 'カメラを開く', '카메라 열기'),
  'Open QR Code': _Translation('Buka Kod QR', '打开二维码', 'QRコードを開く', 'QR 코드 열기'),
  'Scan a booking QR code or enter its booking code manually.': _Translation(
    'Imbas kod QR tempahan atau masukkan kod tempahan secara manual.',
    '扫描预订二维码，或手动输入预订编号。',
    '予約QRコードをスキャンするか、予約コードを入力してください。',
    '예약 QR 코드를 스캔하거나 예약 코드를 직접 입력하세요.',
  ),
  'Live Crowd': _Translation(
    'Kesesakan Langsung',
    '实时人流',
    'リアルタイム混雑',
    '실시간 혼잡도',
  ),
  'Current authenticated check-ins': _Translation(
    'Daftar masuk disahkan semasa',
    '当前已验证签到人数',
    '現在の認証済みチェックイン',
    '현재 인증된 체크인',
  ),
  'Arrivals in the last 15 minutes': _Translation(
    'Ketibaan dalam 15 minit terakhir',
    '过去 15 分钟到达人数',
    '直近15分の来場者',
    '최근 15분 도착자',
  ),
  'Visitor Statistics': _Translation(
    'Statistik Pelawat',
    '游客统计',
    '来場者統計',
    '방문객 통계',
  ),
  'Revenue & Promotion': _Translation(
    'Hasil & Promosi',
    '收入与促销',
    '収益とプロモーション',
    '매출 및 프로모션',
  ),
  'Revenue and visitors by day': _Translation(
    'Hasil dan pelawat mengikut hari',
    '每日收入与游客人数',
    '日別の収益と来場者',
    '일별 매출 및 방문객',
  ),
  'Off-Peak Promotion Suggestion': _Translation(
    'Cadangan Promosi Luar Puncak',
    '非高峰期促销建议',
    'オフピーク販促提案',
    '비혼잡 시간 프로모션 제안',
  ),
  'Suggested Offer': _Translation(
    'Tawaran Dicadangkan',
    '建议优惠',
    'おすすめオファー',
    '추천 혜택',
  ),
  'Suggested Time': _Translation('Masa Dicadangkan', '建议时间', 'おすすめ時間', '추천 시간'),
  'Expected Benefit': _Translation(
    'Manfaat Dijangka',
    '预期效益',
    '期待される効果',
    '예상 효과',
  ),
  'Approve': _Translation('Luluskan', '批准', '承認', '승인'),
  'Reject': _Translation('Tolak', '拒绝', '却下', '거부'),
  'Review': _Translation('Semak', '审核', '確認', '검토'),
  'Choose': _Translation('Pilih', '选择', '選択', '선택'),
  'Reason': _Translation('Sebab', '原因', '理由', '사유'),
  'All': _Translation('Semua', '全部', 'すべて', '전체'),
  'Tickets': _Translation('Tiket', '工单', 'チケット', '티켓'),
  'Critical': _Translation('Kritikal', '严重', '緊急', '심각'),
  'Off-peak': _Translation('Luar puncak', '非高峰期', 'オフピーク', '비혼잡 시간'),
  'Unable to load this image.': _Translation(
    'Imej ini tidak dapat dimuatkan.',
    '无法加载此图片。',
    '画像を読み込めませんでした。',
    '이미지를 불러올 수 없습니다.',
  ),
  'View details': _Translation('Lihat butiran', '查看详情', '詳細を表示', '상세 보기'),
  'View slot': _Translation('Lihat slot', '查看时段', '時間枠を表示', '시간대 보기'),
  'View Trips': _Translation('Lihat Perjalanan', '查看行程', '旅行を表示', '여행 보기'),
  'View alternative slots': _Translation(
    'Lihat slot alternatif',
    '查看其他时段',
    '別の時間枠を表示',
    '대체 시간대 보기',
  ),
  'View quieter alternatives': _Translation(
    'Lihat pilihan yang kurang sesak',
    '查看较少拥挤的选择',
    'より空いている候補を見る',
    '덜 혼잡한 대안 보기',
  ),
  'Go Back': _Translation('Kembali', '返回', '戻る', '뒤로'),
  'Address': _Translation('Alamat', '地址', '住所', '주소'),
  'All Feedback': _Translation(
    'Semua Maklum Balas',
    '全部反馈',
    'すべてのフィードバック',
    '모든 피드백',
  ),
  'Attraction Configuration': _Translation(
    'Konfigurasi Tarikan',
    '景点配置',
    '観光地設定',
    '관광지 설정',
  ),
  'Attraction Type & Check-In': _Translation(
    'Jenis Tarikan & Daftar Masuk',
    '景点类型与签到',
    '観光地タイプとチェックイン',
    '관광지 유형 및 체크인',
  ),
  'Active & Upcoming Slots': _Translation(
    'Slot Aktif & Akan Datang',
    '当前及即将开放的时段',
    '有効・今後の時間枠',
    '활성 및 예정 시간대',
  ),
  'Booking code': _Translation('Kod tempahan', '预订编号', '予約コード', '예약 코드'),
  'Business Information': _Translation(
    'Maklumat Perniagaan',
    '商业资料',
    '事業者情報',
    '사업자 정보',
  ),
  'Business Operating Licence': _Translation(
    'Lesen Operasi Perniagaan',
    '营业执照',
    '営業許可証',
    '사업 운영 허가증',
  ),
  'Business Registration Certificate': _Translation(
    'Sijil Pendaftaran Perniagaan',
    '商业注册证书',
    '事業登録証明書',
    '사업자 등록증',
  ),
  'Capacity & Crowd Levels': _Translation(
    'Kapasiti & Tahap Kesesakan',
    '容量与人流等级',
    '定員と混雑度',
    '수용 인원 및 혼잡도',
  ),
  'Category': _Translation('Kategori', '类别', 'カテゴリー', '카테고리'),
  'Code': _Translation('Kod', '编号', 'コード', '코드'),
  'Comment': _Translation('Komen', '评论', 'コメント', '의견'),
  'Complete processing history': _Translation(
    'Sejarah pemprosesan lengkap',
    '完整处理记录',
    'すべての処理履歴',
    '전체 처리 기록',
  ),
  'Completed visit': _Translation('Lawatan selesai', '已完成参观', '訪問完了', '완료된 방문'),
  'Core Details': _Translation('Butiran Utama', '主要资料', '基本情報', '핵심 정보'),
  'Create Account': _Translation('Cipta Akaun', '建立账户', 'アカウント作成', '계정 만들기'),
  'Create New Slot': _Translation(
    'Cipta Slot Baharu',
    '建立新时段',
    '新しい時間枠を作成',
    '새 시간대 만들기',
  ),
  'Crowd comfort': _Translation(
    'Keselesaan kesesakan',
    '人流舒适度',
    '混雑快適度',
    '혼잡 쾌적도',
  ),
  'Current password': _Translation(
    'Kata laluan semasa',
    '当前密码',
    '現在のパスワード',
    '현재 비밀번호',
  ),
  'Confirm new password': _Translation(
    'Sahkan kata laluan baharu',
    '确认新密码',
    '新しいパスワードを確認',
    '새 비밀번호 확인',
  ),
  'Description': _Translation('Penerangan', '说明', '説明', '설명'),
  'Email Address': _Translation('Alamat E-mel', '电子邮箱', 'メールアドレス', '이메일 주소'),
  'Enter your password': _Translation(
    'Masukkan kata laluan',
    '输入密码',
    'パスワードを入力',
    '비밀번호 입력',
  ),
  'Estimated Waiting Time': _Translation(
    'Anggaran Masa Menunggu',
    '预计等候时间',
    '推定待ち時間',
    '예상 대기 시간',
  ),
  'Estimated crowd': _Translation(
    'Anggaran kesesakan',
    '预计人流',
    '混雑予測',
    '예상 혼잡도',
  ),
  'Full Name': _Translation('Nama Penuh', '姓名', '氏名', '성명'),
  'General Information': _Translation('Maklumat Umum', '一般资料', '一般情報', '일반 정보'),
  'Geofence Check-in': _Translation(
    'Daftar Masuk Geofence',
    '地理围栏签到',
    'ジオフェンスチェックイン',
    '지오펜스 체크인',
  ),
  'Geographic Data': _Translation('Data Geografi', '地理资料', '地理情報', '지리 정보'),
  'Guidelines & Rules': _Translation(
    'Garis Panduan & Peraturan',
    '指南与规则',
    'ガイドラインと規則',
    '안내 및 규칙',
  ),
  'How can we help?': _Translation(
    'Bagaimanakah kami boleh membantu?',
    '我们可以怎样帮助你？',
    'どのようなサポートが必要ですか？',
    '어떻게 도와드릴까요?',
  ),
  'Itinerary name': _Translation('Nama jadual', '行程名称', '旅程名', '일정 이름'),
  'Leave blank for any budget': _Translation(
    'Kosongkan untuk sebarang bajet',
    '留空表示不限预算',
    '予算指定なしは空欄',
    '예산 제한이 없으면 비워 두세요',
  ),
  'Location': _Translation('Lokasi', '地点', '場所', '위치'),
  'Maintenance & Closure': _Translation(
    'Penyelenggaraan & Penutupan',
    '维护与关闭',
    'メンテナンスと休業',
    '유지보수 및 폐쇄',
  ),
  'Maintenance Blocks': _Translation(
    'Tempoh Penyelenggaraan',
    '维护时段',
    'メンテナンス時間',
    '유지보수 시간',
  ),
  'Manage Visit Slots': _Translation(
    'Urus Slot Lawatan',
    '管理参观时段',
    '訪問時間枠を管理',
    '방문 시간대 관리',
  ),
  'Manual Booking Code': _Translation(
    'Kod Tempahan Manual',
    '手动输入预订编号',
    '予約コードを手入力',
    '예약 코드 직접 입력',
  ),
  'Maximum budget (RM)': _Translation(
    'Bajet maksimum (RM)',
    '最高预算（RM）',
    '最大予算（RM）',
    '최대 예산(RM)',
  ),
  'Maximum distance': _Translation('Jarak maksimum', '最远距离', '最大距離', '최대 거리'),
  'Maximum price': _Translation('Harga maksimum', '最高价格', '最高価格', '최대 가격'),
  'Media Gallery': _Translation('Galeri Media', '媒体图库', 'メディアギャラリー', '미디어 갤러리'),
  'My Feedback': _Translation(
    'Maklum Balas Saya',
    '我的反馈',
    '自分のフィードバック',
    '내 피드백',
  ),
  'My Report Status': _Translation(
    'Status Laporan Saya',
    '我的报告状态',
    '報告状況',
    '내 신고 상태',
  ),
  'My Support Tickets': _Translation(
    'Tiket Sokongan Saya',
    '我的支持工单',
    '自分のサポートチケット',
    '내 지원 티켓',
  ),
  'New password': _Translation(
    'Kata laluan baharu',
    '新密码',
    '新しいパスワード',
    '새 비밀번호',
  ),
  'Operating & Capacity': _Translation(
    'Operasi & Kapasiti',
    '运营与容量',
    '運営と定員',
    '운영 및 수용 인원',
  ),
  'Operating Configuration': _Translation(
    'Konfigurasi Operasi',
    '运营配置',
    '運営設定',
    '운영 설정',
  ),
  'Operator Report Queue': _Translation(
    'Barisan Laporan Pengendali',
    '营运商报告队列',
    '運営者レポート一覧',
    '운영자 신고 대기열',
  ),
  'Operator Verification': _Translation(
    'Pengesahan Pengendali',
    '营运商验证',
    '運営者確認',
    '운영자 인증',
  ),
  'Overall experience': _Translation(
    'Pengalaman keseluruhan',
    '整体体验',
    '総合体験',
    '전반적인 경험',
  ),
  'Password': _Translation('Kata Laluan', '密码', 'パスワード', '비밀번호'),
  'Personal Details': _Translation('Butiran Peribadi', '个人资料', '個人情報', '개인 정보'),
  'Phone Number': _Translation('Nombor Telefon', '电话号码', '電話番号', '전화번호'),
  'Preferred Language': _Translation('Bahasa Pilihan', '首选语言', '優先言語', '기본 언어'),
  'Preferred crowd level': _Translation(
    'Tahap kesesakan pilihan',
    '首选人流程度',
    '希望する混雑度',
    '선호 혼잡도',
  ),
  'Recommendation': _Translation('Cadangan', '推荐', 'おすすめ', '추천'),
  'Related visit': _Translation('Lawatan berkaitan', '相关行程', '関連する訪問', '관련 방문'),
  'Representative Details': _Translation(
    'Butiran Wakil',
    '代表资料',
    '担当者情報',
    '담당자 정보',
  ),
  'Representative Identity Document': _Translation(
    'Dokumen Pengenalan Wakil',
    '代表身份证明文件',
    '担当者本人確認書類',
    '담당자 신분증',
  ),
  'Resolution note': _Translation(
    'Catatan penyelesaian',
    '解决说明',
    '解決メモ',
    '해결 메모',
  ),
  'Resolve Report': _Translation(
    'Selesaikan Laporan',
    '处理报告',
    '報告を解決',
    '신고 해결',
  ),
  'Review Notes': _Translation('Catatan Semakan', '审核备注', '審査メモ', '검토 메모'),
  'Roaming Staff QR Fallback': _Translation(
    'QR Sandaran Kakitangan Bergerak',
    '流动员工二维码备用签到',
    '巡回スタッフ用QR代替手段',
    '순회 직원 QR 대체 수단',
  ),
  'Rules': _Translation('Peraturan', '规则', '規則', '규칙'),
  'Search name, category or location': _Translation(
    'Cari nama, kategori atau lokasi',
    '搜索名称、类别或地点',
    '名前、カテゴリー、場所を検索',
    '이름, 카테고리 또는 위치 검색',
  ),
  'Search ticket ID, subject, tourist, or attraction': _Translation(
    'Cari ID tiket, tajuk, pelancong atau tarikan',
    '搜索工单编号、主题、游客或景点',
    'チケットID、件名、観光客、観光地を検索',
    '티켓 ID, 제목, 관광객 또는 관광지 검색',
  ),
  'Search your conversations': _Translation(
    'Cari perbualan anda',
    '搜索聊天记录',
    '会話を検索',
    '대화 검색',
  ),
  'Submit Rating & Feedback': _Translation(
    'Hantar Penilaian & Maklum Balas',
    '提交评分与反馈',
    '評価とフィードバックを送信',
    '평점 및 피드백 제출',
  ),
  'Submitted Media': _Translation(
    'Media Dihantar',
    '已提交媒体',
    '提出済みメディア',
    '제출된 미디어',
  ),
  'Suggested Promotion': _Translation(
    'Promosi Dicadangkan',
    '建议促销',
    'おすすめプロモーション',
    '추천 프로모션',
  ),
  'Support overview': _Translation(
    'Ringkasan sokongan',
    '支持概览',
    'サポート概要',
    '지원 개요',
  ),
  'Ticket status': _Translation('Status tiket', '工单状态', 'チケット状態', '티켓 상태'),
  'Track your complaints': _Translation(
    'Jejak aduan anda',
    '追踪你的投诉',
    '苦情を追跡',
    '불만 추적',
  ),
  'Travel radius (km)': _Translation(
    'Radius perjalanan (km)',
    '出行范围（公里）',
    '移動範囲（km）',
    '이동 반경(km)',
  ),
  'User Management': _Translation(
    'Pengurusan Pengguna',
    '用户管理',
    'ユーザー管理',
    '사용자 관리',
  ),
  'Verification Documents': _Translation(
    'Dokumen Pengesahan',
    '验证文件',
    '確認書類',
    '인증 문서',
  ),
  'View Report Status': _Translation(
    'Lihat Status Laporan',
    '查看报告状态',
    '報告状況を表示',
    '신고 상태 보기',
  ),
  'Visitor Information': _Translation(
    'Maklumat Pelawat',
    '游客资料',
    '来場者情報',
    '방문객 정보',
  ),
  'Visitor guidelines': _Translation(
    'Garis panduan pelawat',
    '游客指南',
    '来場者ガイドライン',
    '방문객 안내',
  ),
  'Write a clear response or request more information…': _Translation(
    'Tulis respons yang jelas atau minta maklumat lanjut…',
    '清楚回复或要求更多资料……',
    '明確な返信、または追加情報の依頼を入力…',
    '명확한 답변을 작성하거나 추가 정보를 요청하세요…',
  ),
  'Your Attractions': _Translation('Tarikan Anda', '你的景点', '自分の観光地', '내 관광지'),
  'Your conversations': _Translation('Perbualan anda', '你的对话', '会話一覧', '내 대화'),
  'Available attractions': _Translation(
    'Tarikan tersedia',
    '可用景点',
    '利用可能な観光地',
    '이용 가능한 관광지',
  ),
  'Live crowd status': _Translation(
    'Status kesesakan langsung',
    '实时人流状态',
    'リアルタイム混雑状況',
    '실시간 혼잡 상태',
  ),
  'Transportation help': _Translation(
    'Bantuan pengangkutan',
    '交通协助',
    '交通案内',
    '교통 도움',
  ),
  'Overcrowding': _Translation('Terlalu Sesak', '过度拥挤', '混雑', '과밀'),
  'Facility Damage': _Translation(
    'Kerosakan Kemudahan',
    '设施损坏',
    '設備の破損',
    '시설 파손',
  ),
  'Safety Issue': _Translation('Isu Keselamatan', '安全问题', '安全上の問題', '안전 문제'),
  'Staff Service': _Translation(
    'Perkhidmatan Kakitangan',
    '员工服务',
    'スタッフ対応',
    '직원 서비스',
  ),
  'Other': _Translation('Lain-lain', '其他', 'その他', '기타'),
  'Confirmed': _Translation('Disahkan', '已确认', '確定済み', '확정됨'),
  'Cancelled': _Translation('Dibatalkan', '已取消', 'キャンセル済み', '취소됨'),
  'Completed': _Translation('Selesai', '已完成', '完了', '완료됨'),
  'Upcoming': _Translation('Akan Datang', '即将开始', '今後', '예정'),
  'Past': _Translation('Lepas', '过去', '過去', '지난 일정'),
  'Booking QR is missing.': _Translation(
    'Kod QR tempahan tiada.',
    '缺少预订二维码。',
    '予約QRコードがありません。',
    '예약 QR 코드가 없습니다.',
  ),
  'Booking confirmation is missing.': _Translation(
    'Pengesahan tempahan tiada.',
    '缺少预订确认资料。',
    '予約確認情報がありません。',
    '예약 확인 정보가 없습니다.',
  ),
  'Booking details are missing.': _Translation(
    'Butiran tempahan tiada.',
    '缺少预订详情。',
    '予約詳細がありません。',
    '예약 상세 정보가 없습니다.',
  ),
  'Capacity Alert': _Translation(
    'Amaran Kapasiti',
    '容量提醒',
    '定員アラート',
    '수용 인원 알림',
  ),
  'Capacity, closures, overlaps and travel time are checked again when you confirm.':
      _Translation(
        'Kapasiti, penutupan, pertindihan dan masa perjalanan disemak semula apabila anda mengesahkan.',
        '确认时，系统会再次检查容量、关闭时段、时间冲突和行程时间。',
        '確定時に定員、休業、重複、移動時間を再確認します。',
        '확인 시 수용 인원, 폐쇄, 일정 중복 및 이동 시간을 다시 확인합니다.',
      ),
  'Could not load alternative slots.': _Translation(
    'Slot alternatif tidak dapat dimuatkan.',
    '无法加载其他时段。',
    '別の時間枠を読み込めませんでした。',
    '대체 시간대를 불러올 수 없습니다.',
  ),
  'Could not load confirmed bookings.': _Translation(
    'Tempahan yang disahkan tidak dapat dimuatkan.',
    '无法加载已确认预订。',
    '確定済み予約を読み込めませんでした。',
    '확정된 예약을 불러올 수 없습니다.',
  ),
  'Demo preferences': _Translation('Pilihan demo', '演示偏好', 'デモ設定', '데모 환경설정'),
  'Distance unavailable; conservative travel estimate used': _Translation(
    'Jarak tidak tersedia; anggaran perjalanan konservatif digunakan',
    '无法取得距离；系统使用较保守的行程估算',
    '距離を取得できないため余裕のある移動時間を使用します',
    '거리를 확인할 수 없어 여유 있는 이동 시간을 사용합니다',
  ),
  'Enter a valid budget and travel radius between 1 and 200 km.': _Translation(
    'Masukkan bajet yang sah dan radius perjalanan antara 1 hingga 200 km.',
    '请输入有效预算，以及 1 至 200 公里的出行范围。',
    '有効な予算と1～200kmの移動範囲を入力してください。',
    '유효한 예산과 1~200km의 이동 반경을 입력하세요.',
  ),
  'I agree to the Terms of Service and Privacy Policy.': _Translation(
    'Saya bersetuju dengan Terma Perkhidmatan dan Dasar Privasi.',
    '我同意服务条款和隐私政策。',
    '利用規約とプライバシーポリシーに同意します。',
    '서비스 약관 및 개인정보 처리방침에 동의합니다.',
  ),
  'Keep': _Translation('Kekalkan', '保留', '保持', '유지'),
  'MODERATE': _Translation('SEDERHANA', '中等', '普通', '보통'),
  'TOURIST': _Translation('PELANCONG', '游客', '観光客', '관광객'),
  'No approved attraction is available for a ticket.': _Translation(
    'Tiada tarikan yang diluluskan tersedia untuk tiket.',
    '目前没有可用于建立工单的已审核景点。',
    'チケットに利用できる承認済み観光地がありません。',
    '티켓에 사용할 수 있는 승인된 관광지가 없습니다.',
  ),
  'No attraction selected.': _Translation(
    'Tiada tarikan dipilih.',
    '尚未选择景点。',
    '観光地が選択されていません。',
    '선택된 관광지가 없습니다.',
  ),
  'No completed visits are waiting for feedback.': _Translation(
    'Tiada lawatan selesai yang menunggu maklum balas.',
    '没有等待反馈的已完成行程。',
    'フィードバック待ちの訪問はありません。',
    '피드백을 기다리는 완료된 방문이 없습니다.',
  ),
  'No confirmed bookings are available for check-in.': _Translation(
    'Tiada tempahan disahkan tersedia untuk daftar masuk.',
    '没有可签到的已确认预订。',
    'チェックイン可能な確定済み予約はありません。',
    '체크인 가능한 확정 예약이 없습니다.',
  ),
  'No facilities listed.': _Translation(
    'Tiada kemudahan disenaraikan.',
    '未列出设施。',
    '設備情報はありません。',
    '등록된 시설이 없습니다.',
  ),
  'No future open slots are available.': _Translation(
    'Tiada slot terbuka akan datang.',
    '没有未来可用的开放时段。',
    '今後利用できる時間枠はありません。',
    '예정된 이용 가능 시간대가 없습니다.',
  ),
  'No ratings yet · Rating data will be supplied by Module 5.': _Translation(
    'Belum ada penilaian · Data penilaian akan dibekalkan oleh Modul 5.',
    '暂无评分 · 评分数据将由模块 5 提供。',
    '評価なし · 評価データはモジュール5から提供されます。',
    '평점 없음 · 평점 데이터는 모듈 5에서 제공됩니다.',
  ),
  'No suitable alternative slots are available.': _Translation(
    'Tiada slot alternatif yang sesuai.',
    '没有合适的其他时段。',
    '適切な代替時間枠はありません。',
    '적절한 대체 시간대가 없습니다.',
  ),
  'No suitable approved attractions are currently available.': _Translation(
    'Tiada tarikan diluluskan yang sesuai pada masa ini.',
    '目前没有合适的已审核景点。',
    '現在、適切な承認済み観光地はありません。',
    '현재 적절한 승인된 관광지가 없습니다.',
  ),
  'Operating hours not provided.': _Translation(
    'Waktu operasi tidak diberikan.',
    '未提供开放时间。',
    '営業時間が登録されていません。',
    '운영 시간이 제공되지 않았습니다.',
  ),
  'Recommendations need a signed-in tourist and Module 2 preferences.':
      _Translation(
        'Cadangan memerlukan pelancong yang telah log masuk dan pilihan Modul 2.',
        '推荐功能需要游客登录并设置模块 2 偏好。',
        'おすすめには観光客のログインとモジュール2の設定が必要です。',
        '추천을 사용하려면 관광객 로그인과 모듈 2 환경설정이 필요합니다.',
      ),
  'See all': _Translation('Lihat semua', '查看全部', 'すべて表示', '모두 보기'),
  'Select two or three attractions from Discover.': _Translation(
    'Pilih dua atau tiga tarikan daripada Teroka.',
    '请从“发现”中选择两个或三个景点。',
    '「見つける」から2～3か所選択してください。',
    '둘러보기에서 관광지 2~3개를 선택하세요.',
  ),
  'This attraction is not available to tourists.': _Translation(
    'Tarikan ini tidak tersedia untuk pelancong.',
    '此景点目前不对游客开放。',
    'この観光地は観光客が利用できません。',
    '이 관광지는 관광객이 이용할 수 없습니다.',
  ),
  'Up to RM10': _Translation('Sehingga RM10', '最高 RM10', 'RM10まで', '최대 RM10'),
  'Up to RM25': _Translation('Sehingga RM25', '最高 RM25', 'RM25まで', '최대 RM25'),
  'Up to RM50': _Translation('Sehingga RM50', '最高 RM50', 'RM50まで', '최대 RM50'),
  'Within 3 km': _Translation('Dalam 3 km', '3 公里以内', '3km以内', '3km 이내'),
  'Within 10 km': _Translation('Dalam 10 km', '10 公里以内', '10km以内', '10km 이내'),
  'Within 25 km': _Translation('Dalam 25 km', '25 公里以内', '25km以内', '25km 이내'),
  'View Geofence': _Translation(
    'Lihat Geofence',
    '查看地理围栏',
    'ジオフェンスを表示',
    '지오펜스 보기',
  ),
  'Your device location is verified securely by Supabase.': _Translation(
    'Lokasi peranti anda disahkan dengan selamat oleh Supabase.',
    '你的设备位置已由 Supabase 安全验证。',
    '端末の位置情報はSupabaseで安全に確認されます。',
    '기기 위치는 Supabase에서 안전하게 확인됩니다.',
  ),
  'Change language': _Translation('Tukar bahasa', '切换语言', '言語を変更', '언어 변경'),
  'Changes are kept for this app session only.': _Translation(
    'Perubahan disimpan untuk sesi aplikasi ini sahaja.',
    '更改仅在本次应用会话中保留。',
    '変更は現在のアプリセッション中のみ保持されます。',
    '변경 사항은 현재 앱 세션에만 유지됩니다.',
  ),
  'Conversation options': _Translation(
    'Pilihan perbualan',
    '对话选项',
    '会話オプション',
    '대화 옵션',
  ),
  'Create ticket': _Translation('Cipta tiket', '建立工单', 'チケットを作成', '티켓 만들기'),
  'Edit preferences': _Translation('Edit pilihan', '编辑偏好', '設定を編集', '환경설정 편집'),
  'Language': _Translation('Bahasa', '语言', '言語', '언어'),
  'Nearby': _Translation('Berdekatan', '附近', '周辺', '주변'),
  'New conversation': _Translation('Perbualan baharu', '新对话', '新しい会話', '새 대화'),
  'Preferences': _Translation('Pilihan', '偏好设置', '設定', '환경설정'),
  'Recommendations': _Translation('Cadangan', '推荐', 'おすすめ', '추천'),
  'Remove photo': _Translation('Buang foto', '移除照片', '写真を削除', '사진 제거'),
  'Support menu': _Translation('Menu sokongan', '支持菜单', 'サポートメニュー', '지원 메뉴'),
  'Use at least 8 characters.': _Translation(
    'Gunakan sekurang-kurangnya 8 aksara.',
    '请至少使用 8 个字符。',
    '8文字以上入力してください。',
    '8자 이상 입력하세요.',
  ),
};
