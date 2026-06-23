///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'Toko Dedy'
	String get app_name => 'Toko Dedy';

	late final Translations$login$en login = Translations$login$en._(_root);
	late final Translations$home$en home = Translations$home$en._(_root);
	late final Translations$pin$en pin = Translations$pin$en._(_root);
	late final Translations$error$en error = Translations$error$en._(_root);
	late final Translations$dashboard$en dashboard = Translations$dashboard$en._(_root);
	late final Translations$quick_actions$en quick_actions = Translations$quick_actions$en._(_root);
	late final Translations$price_update$en price_update = Translations$price_update$en._(_root);
	late final Translations$navigation$en navigation = Translations$navigation$en._(_root);
	late final Translations$dialog$en dialog = Translations$dialog$en._(_root);
	late final Translations$cashier$en cashier = Translations$cashier$en._(_root);
	late final Translations$product$en product = Translations$product$en._(_root);
}

// Path: login
class Translations$login$en {
	Translations$login$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Login'
	String get title => 'Login';

	/// en: 'Email'
	String get email_hint => 'Email';

	/// en: 'Password'
	String get password_hint => 'Password';

	/// en: 'Masuk'
	String get login_btn => 'Masuk';

	/// en: 'Belum punya toko? Daftar'
	String get register_prompt => 'Belum punya toko? Daftar';
}

// Path: home
class Translations$home$en {
	Translations$home$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Selamat datang,'
	String get welcome => 'Selamat datang,';

	/// en: 'Keluar'
	String get logout => 'Keluar';
}

// Path: pin
class Translations$pin$en {
	Translations$pin$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Masukkan PIN'
	String get title => 'Masukkan PIN';

	/// en: 'Buat PIN Baru'
	String get setup_title => 'Buat PIN Baru';

	/// en: 'Konfirmasi PIN'
	String get verify_title => 'Konfirmasi PIN';
}

// Path: error
class Translations$error$en {
	Translations$error$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Terjadi kesalahan yang tidak diketahui'
	String get unknown => 'Terjadi kesalahan yang tidak diketahui';

	/// en: 'Tidak ada koneksi internet'
	String get network => 'Tidak ada koneksi internet';

	/// en: 'Hanya owner yang bisa akses Laporan'
	String get owner_only_report => 'Hanya owner yang bisa akses Laporan';
}

// Path: dashboard
class Translations$dashboard$en {
	Translations$dashboard$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'OMZET HARI INI'
	String get omzet_today => 'OMZET HARI INI';

	/// en: 'Transaksi'
	String get transaction => 'Transaksi';

	/// en: 'Terjual'
	String get sold => 'Terjual';

	/// en: 'Stok Menipis'
	String get low_stock => 'Stok Menipis';

	/// en: 'Lihat semua'
	String get see_all => 'Lihat semua';

	/// en: 'Sisa'
	String get remaining => 'Sisa';
}

// Path: quick_actions
class Translations$quick_actions$en {
	Translations$quick_actions$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Aksi Cepat'
	String get title => 'Aksi Cepat';

	/// en: 'KASIR'
	String get cashier => 'KASIR';

	/// en: 'LAPORAN'
	String get report => 'LAPORAN';

	/// en: 'PRODUK'
	String get product => 'PRODUK';

	/// en: 'TAMBAH'
	String get add => 'TAMBAH';
}

// Path: price_update
class Translations$price_update$en {
	Translations$price_update$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Update Harga Barang'
	String get title => 'Update Harga Barang';

	/// en: 'Produk Dihapus'
	String get product_deleted => 'Produk Dihapus';
}

// Path: navigation
class Translations$navigation$en {
	Translations$navigation$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Dashboard'
	String get dashboard => 'Dashboard';

	/// en: 'Kasir'
	String get kasir => 'Kasir';

	/// en: 'Produk'
	String get produk => 'Produk';

	/// en: 'Riwayat Transaksi'
	String get transaksi => 'Riwayat Transaksi';

	/// en: 'Laporan'
	String get laporan => 'Laporan';

	/// en: 'Pembelian'
	String get pembelian => 'Pembelian';

	/// en: 'Purchase Order'
	String get purchase_order => 'Purchase Order';

	/// en: 'Supplier'
	String get supplier => 'Supplier';

	/// en: 'Hutang'
	String get hutang => 'Hutang';

	/// en: 'Online Order'
	String get online_order => 'Online Order';

	/// en: 'Pengguna'
	String get pengguna => 'Pengguna';

	/// en: 'Pengaturan'
	String get pengaturan => 'Pengaturan';

	/// en: 'KASIR'
	String get group_kasir => 'KASIR';

	/// en: 'STOK & PEMBELIAN'
	String get group_stok => 'STOK & PEMBELIAN';

	/// en: 'KEUANGAN'
	String get group_keuangan => 'KEUANGAN';

	/// en: 'ONLINE'
	String get group_online => 'ONLINE';

	/// en: 'ADMIN'
	String get group_admin => 'ADMIN';

	/// en: 'PENGATURAN'
	String get group_pengaturan => 'PENGATURAN';
}

// Path: dialog
class Translations$dialog$en {
	Translations$dialog$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Lengkapi Email'
	String get email_title => 'Lengkapi Email';

	/// en: 'Anda login menggunakan username. Silakan isi email untuk keamanan akun dan fitur lupa password.'
	String get email_subtitle => 'Anda login menggunakan username. Silakan isi email untuk keamanan akun dan fitur lupa password.';

	/// en: 'Email'
	String get email_label => 'Email';

	/// en: 'Nanti'
	String get btn_nanti => 'Nanti';

	/// en: 'Simpan'
	String get btn_simpan => 'Simpan';

	/// en: 'Email tidak boleh kosong'
	String get email_empty => 'Email tidak boleh kosong';

	/// en: 'Format email tidak valid'
	String get email_invalid => 'Format email tidak valid';

	/// en: 'Gagal menyimpan'
	String get save_failed => 'Gagal menyimpan';
}

// Path: cashier
class Translations$cashier$en {
	Translations$cashier$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cari atau scan produk... (Ctrl+F)'
	String get search_hint => 'Cari atau scan produk... (Ctrl+F)';

	/// en: 'Printer terhubung'
	String get printer_connected => 'Printer terhubung';

	/// en: 'Printer tidak terhubung'
	String get printer_disconnected => 'Printer tidak terhubung';

	/// en: 'Pengaturan'
	String get printer_settings => 'Pengaturan';

	/// en: 'Buka Laci'
	String get btn_open_drawer => 'Buka Laci';

	/// en: 'Keranjang'
	String get cart_title => 'Keranjang';

	/// en: 'Keranjang kosong'
	String get cart_empty => 'Keranjang kosong';

	/// en: 'Cari atau scan produk di panel kiri'
	String get cart_empty_hint => 'Cari atau scan produk di panel kiri';

	/// en: 'Kosongkan'
	String get btn_clear => 'Kosongkan';

	/// en: 'Pending'
	String get btn_pending => 'Pending';

	/// en: 'Catat Hutang'
	String get btn_debt => 'Catat Hutang';

	/// en: 'Bayar Sekarang'
	String get btn_pay => 'Bayar Sekarang';

	/// en: 'Memproses...'
	String get btn_processing => 'Memproses...';

	/// en: 'Simpan'
	String get btn_save => 'Simpan';

	/// en: 'Batal'
	String get btn_cancel => 'Batal';

	/// en: 'Diskon Item:'
	String get discount_item => 'Diskon Item:';

	/// en: 'Diskon Global:'
	String get discount_global_label => 'Diskon Global:';

	/// en: 'Total'
	String get total => 'Total';

	/// en: 'Produk tidak ditemukan'
	String get product_not_found => 'Produk tidak ditemukan';

	late final Translations$cashier$dialog_payment$en dialog_payment = Translations$cashier$dialog_payment$en._(_root);
	late final Translations$cashier$dialog_printer$en dialog_printer = Translations$cashier$dialog_printer$en._(_root);
	late final Translations$cashier$dialog_discount$en dialog_discount = Translations$cashier$dialog_discount$en._(_root);
	late final Translations$cashier$dialog_qty$en dialog_qty = Translations$cashier$dialog_qty$en._(_root);
	late final Translations$cashier$dialog_debt$en dialog_debt = Translations$cashier$dialog_debt$en._(_root);
	late final Translations$cashier$dialog_pending$en dialog_pending = Translations$cashier$dialog_pending$en._(_root);
	late final Translations$cashier$dialog_unit$en dialog_unit = Translations$cashier$dialog_unit$en._(_root);
	late final Translations$cashier$dialog_print$en dialog_print = Translations$cashier$dialog_print$en._(_root);
}

// Path: product
class Translations$product$en {
	Translations$product$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cari produk...'
	String get search_hint => 'Cari produk...';

	/// en: 'Stok Minimum'
	String get stock_minimum => 'Stok Minimum';

	/// en: 'Tambah Produk'
	String get add_product => 'Tambah Produk';

	/// en: 'Semua'
	String get category_all => 'Semua';

	/// en: 'Kategori'
	String get category_label => 'Kategori';

	/// en: 'Semua'
	String get filter_all => 'Semua';

	/// en: 'Stok Tipis'
	String get filter_low_stock => 'Stok Tipis';

	/// en: 'Habis'
	String get filter_out_of_stock => 'Habis';

	/// en: 'Arsip'
	String get filter_archived => 'Arsip';

	/// en: '{count} produk'
	String get count_format => '{count} produk';

	/// en: 'Produk "{query}" tidak ditemukan'
	String get not_found => 'Produk "{query}" tidak ditemukan';

	/// en: 'Belum ada produk'
	String get empty => 'Belum ada produk';

	/// en: '{count} dipilih'
	String get batch_action => '{count} dipilih';

	/// en: 'Arsipkan'
	String get btn_archive => 'Arsipkan';

	/// en: 'Hapus'
	String get btn_delete => 'Hapus';

	/// en: 'Batal'
	String get btn_cancel => 'Batal';

	/// en: 'Hapus Produk'
	String get dialog_delete_title => 'Hapus Produk';

	/// en: 'Hapus {count} produk permanen? Tindakan ini tidak bisa dibatalkan.'
	String get dialog_delete_body => 'Hapus {count} produk permanen? Tindakan ini tidak bisa dibatalkan.';

	/// en: 'Hapus Semua'
	String get btn_delete_all => 'Hapus Semua';

	/// en: 'Hapus Produk Permanen?'
	String get dialog_delete_perm_title => 'Hapus Produk Permanen?';

	/// en: 'Apakah Anda yakin ingin menghapus produk ini secara permanen? Aksi ini tidak dapat dibatalkan.'
	String get dialog_delete_perm_body => 'Apakah Anda yakin ingin menghapus produk ini secara permanen? Aksi ini tidak dapat dibatalkan.';

	/// en: 'Hapus Permanen'
	String get btn_delete_perm => 'Hapus Permanen';

	/// en: '✓ Tersimpan!'
	String get saved_badge => '✓ Tersimpan!';

	late final Translations$product$form$en form = Translations$product$form$en._(_root);
}

// Path: cashier.dialog_payment
class Translations$cashier$dialog_payment$en {
	Translations$cashier$dialog_payment$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Konfirmasi Pembayaran'
	String get title => 'Konfirmasi Pembayaran';

	/// en: 'Printer Terhubung'
	String get printer_ok => 'Printer Terhubung';

	/// en: 'Printer Tidak Terhubung'
	String get printer_err => 'Printer Tidak Terhubung';

	/// en: 'Jumlah Bayar'
	String get pay_amount => 'Jumlah Bayar';

	/// en: 'Uang Pas'
	String get exact_money => 'Uang Pas';

	/// en: 'Kembalian:'
	String get change => 'Kembalian:';

	/// en: 'Kurang:'
	String get lack => 'Kurang:';

	/// en: 'Proses Bayar'
	String get btn_process => 'Proses Bayar';
}

// Path: cashier.dialog_printer
class Translations$cashier$dialog_printer$en {
	Translations$cashier$dialog_printer$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Printer Thermal'
	String get title => 'Printer Thermal';

	/// en: 'Terhubung'
	String get connected => 'Terhubung';

	/// en: 'Tidak terhubung'
	String get disconnected => 'Tidak terhubung';

	/// en: 'Printer menggunakan koneksi Network (HTTP) ke print_server.py.'
	String get desc => 'Printer menggunakan koneksi Network (HTTP) ke print_server.py.';

	/// en: 'Pengaturan Printer'
	String get settings => 'Pengaturan Printer';

	/// en: 'Tutup'
	String get close => 'Tutup';
}

// Path: cashier.dialog_discount
class Translations$cashier$dialog_discount$en {
	Translations$cashier$dialog_discount$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Diskon -'
	String get title => 'Diskon -';

	/// en: 'Diskon Global'
	String get global_title => 'Diskon Global';

	/// en: 'Tidak'
	String get no_discount => 'Tidak';

	/// en: 'Persen (%)'
	String get percent => 'Persen (%)';

	/// en: 'Nominal (Rp)'
	String get nominal => 'Nominal (Rp)';

	/// en: '10'
	String get hint_percent => '10';

	/// en: '5000'
	String get hint_nominal => '5000';
}

// Path: cashier.dialog_qty
class Translations$cashier$dialog_qty$en {
	Translations$cashier$dialog_qty$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Jumlah Barang'
	String get title => 'Jumlah Barang';

	/// en: 'Ubah Jumlah -'
	String get title_edit => 'Ubah Jumlah -';

	/// en: 'Jumlah'
	String get qty_label => 'Jumlah';

	/// en: 'Masukkan jumlah barang'
	String get qty_hint => 'Masukkan jumlah barang';

	/// en: 'Tambah'
	String get btn_add => 'Tambah';
}

// Path: cashier.dialog_debt
class Translations$cashier$dialog_debt$en {
	Translations$cashier$dialog_debt$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Bayar Hutang'
	String get title => 'Bayar Hutang';

	/// en: 'Nama Pelanggan'
	String get customer_name => 'Nama Pelanggan';

	/// en: 'Masukkan nama pelanggan'
	String get customer_hint => 'Masukkan nama pelanggan';
}

// Path: cashier.dialog_pending
class Translations$cashier$dialog_pending$en {
	Translations$cashier$dialog_pending$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Simpan Pending'
	String get title => 'Simpan Pending';

	/// en: 'Nama Pelanggan *'
	String get customer_required => 'Nama Pelanggan *';

	/// en: 'Catatan'
	String get notes => 'Catatan';

	/// en: 'Pending disimpan untuk'
	String get saved_success => 'Pending disimpan untuk';
}

// Path: cashier.dialog_unit
class Translations$cashier$dialog_unit$en {
	Translations$cashier$dialog_unit$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Pilih Satuan -'
	String get title => 'Pilih Satuan -';
}

// Path: cashier.dialog_print
class Translations$cashier$dialog_print$en {
	Translations$cashier$dialog_print$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cetak Struk?'
	String get title => 'Cetak Struk?';

	/// en: 'Ya, Cetak'
	String get btn_yes => 'Ya, Cetak';

	/// en: 'Tidak'
	String get btn_no => 'Tidak';

	/// en: 'Gagal membuka laci otomatis, gunakan kunci manual'
	String get drawer_failed => 'Gagal membuka laci otomatis, gunakan kunci manual';
}

// Path: product.form
class Translations$product$form$en {
	Translations$product$form$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'DAFTAR SATUAN ({count})'
	String get section_units => 'DAFTAR SATUAN ({count})';

	/// en: 'Tambah Satuan'
	String get btn_add_unit => 'Tambah Satuan';

	/// en: 'Hitung Harga Pokok Dasar'
	String get btn_calc_cost => 'Hitung Harga Pokok Dasar';

	/// en: 'HARGA POKOK'
	String get label_cost => 'HARGA POKOK';

	/// en: 'HARGA JUAL'
	String get label_sell => 'HARGA JUAL';

	/// en: 'KONVERSI'
	String get label_conversion => 'KONVERSI';

	/// en: 'LABA'
	String get label_profit => 'LABA';

	/// en: 'SATUAN DASAR'
	String get type_base => 'SATUAN DASAR';

	/// en: 'BASE'
	String get badge_base => 'BASE';

	/// en: 'Konversi: {value}'
	String get conversion_text => 'Konversi: {value}';

	/// en: 'Harga Pokok'
	String get dialog_cost_title => 'Harga Pokok';

	/// en: 'Harga Jual'
	String get dialog_sell_title => 'Harga Jual';

	/// en: 'Simpan'
	String get btn_save => 'Simpan';

	/// en: 'Batal'
	String get btn_cancel => 'Batal';

	/// en: 'Nama Satuan'
	String get unit_name_hint => 'Nama Satuan';

	/// en: 'Konversi'
	String get conversion_hint => 'Konversi';

	/// en: 'Harga Pokok (Rp)'
	String get cost_hint => 'Harga Pokok (Rp)';

	/// en: 'Harga Jual (Rp)'
	String get sell_hint => 'Harga Jual (Rp)';

	/// en: 'BARU'
	String get placeholder_name => 'BARU';

	/// en: 'Edit Satuan'
	String get edit_title => 'Edit Satuan';

	/// en: 'Simpan Satuan'
	String get btn_save_unit => 'Simpan Satuan';

	/// en: 'Laba'
	String get label_laba => 'Laba';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app_name' => 'Toko Dedy',
			'login.title' => 'Login',
			'login.email_hint' => 'Email',
			'login.password_hint' => 'Password',
			'login.login_btn' => 'Masuk',
			'login.register_prompt' => 'Belum punya toko? Daftar',
			'home.welcome' => 'Selamat datang,',
			'home.logout' => 'Keluar',
			'pin.title' => 'Masukkan PIN',
			'pin.setup_title' => 'Buat PIN Baru',
			'pin.verify_title' => 'Konfirmasi PIN',
			'error.unknown' => 'Terjadi kesalahan yang tidak diketahui',
			'error.network' => 'Tidak ada koneksi internet',
			'error.owner_only_report' => 'Hanya owner yang bisa akses Laporan',
			'dashboard.omzet_today' => 'OMZET HARI INI',
			'dashboard.transaction' => 'Transaksi',
			'dashboard.sold' => 'Terjual',
			'dashboard.low_stock' => 'Stok Menipis',
			'dashboard.see_all' => 'Lihat semua',
			'dashboard.remaining' => 'Sisa',
			'quick_actions.title' => 'Aksi Cepat',
			'quick_actions.cashier' => 'KASIR',
			'quick_actions.report' => 'LAPORAN',
			'quick_actions.product' => 'PRODUK',
			'quick_actions.add' => 'TAMBAH',
			'price_update.title' => 'Update Harga Barang',
			'price_update.product_deleted' => 'Produk Dihapus',
			'navigation.dashboard' => 'Dashboard',
			'navigation.kasir' => 'Kasir',
			'navigation.produk' => 'Produk',
			'navigation.transaksi' => 'Riwayat Transaksi',
			'navigation.laporan' => 'Laporan',
			'navigation.pembelian' => 'Pembelian',
			'navigation.purchase_order' => 'Purchase Order',
			'navigation.supplier' => 'Supplier',
			'navigation.hutang' => 'Hutang',
			'navigation.online_order' => 'Online Order',
			'navigation.pengguna' => 'Pengguna',
			'navigation.pengaturan' => 'Pengaturan',
			'navigation.group_kasir' => 'KASIR',
			'navigation.group_stok' => 'STOK & PEMBELIAN',
			'navigation.group_keuangan' => 'KEUANGAN',
			'navigation.group_online' => 'ONLINE',
			'navigation.group_admin' => 'ADMIN',
			'navigation.group_pengaturan' => 'PENGATURAN',
			'dialog.email_title' => 'Lengkapi Email',
			'dialog.email_subtitle' => 'Anda login menggunakan username. Silakan isi email untuk keamanan akun dan fitur lupa password.',
			'dialog.email_label' => 'Email',
			'dialog.btn_nanti' => 'Nanti',
			'dialog.btn_simpan' => 'Simpan',
			'dialog.email_empty' => 'Email tidak boleh kosong',
			'dialog.email_invalid' => 'Format email tidak valid',
			'dialog.save_failed' => 'Gagal menyimpan',
			'cashier.search_hint' => 'Cari atau scan produk... (Ctrl+F)',
			'cashier.printer_connected' => 'Printer terhubung',
			'cashier.printer_disconnected' => 'Printer tidak terhubung',
			'cashier.printer_settings' => 'Pengaturan',
			'cashier.btn_open_drawer' => 'Buka Laci',
			'cashier.cart_title' => 'Keranjang',
			'cashier.cart_empty' => 'Keranjang kosong',
			'cashier.cart_empty_hint' => 'Cari atau scan produk di panel kiri',
			'cashier.btn_clear' => 'Kosongkan',
			'cashier.btn_pending' => 'Pending',
			'cashier.btn_debt' => 'Catat Hutang',
			'cashier.btn_pay' => 'Bayar Sekarang',
			'cashier.btn_processing' => 'Memproses...',
			'cashier.btn_save' => 'Simpan',
			'cashier.btn_cancel' => 'Batal',
			'cashier.discount_item' => 'Diskon Item:',
			'cashier.discount_global_label' => 'Diskon Global:',
			'cashier.total' => 'Total',
			'cashier.product_not_found' => 'Produk tidak ditemukan',
			'cashier.dialog_payment.title' => 'Konfirmasi Pembayaran',
			'cashier.dialog_payment.printer_ok' => 'Printer Terhubung',
			'cashier.dialog_payment.printer_err' => 'Printer Tidak Terhubung',
			'cashier.dialog_payment.pay_amount' => 'Jumlah Bayar',
			'cashier.dialog_payment.exact_money' => 'Uang Pas',
			'cashier.dialog_payment.change' => 'Kembalian:',
			'cashier.dialog_payment.lack' => 'Kurang:',
			'cashier.dialog_payment.btn_process' => 'Proses Bayar',
			'cashier.dialog_printer.title' => 'Printer Thermal',
			'cashier.dialog_printer.connected' => 'Terhubung',
			'cashier.dialog_printer.disconnected' => 'Tidak terhubung',
			'cashier.dialog_printer.desc' => 'Printer menggunakan koneksi Network (HTTP) ke print_server.py.',
			'cashier.dialog_printer.settings' => 'Pengaturan Printer',
			'cashier.dialog_printer.close' => 'Tutup',
			'cashier.dialog_discount.title' => 'Diskon -',
			'cashier.dialog_discount.global_title' => 'Diskon Global',
			'cashier.dialog_discount.no_discount' => 'Tidak',
			'cashier.dialog_discount.percent' => 'Persen (%)',
			'cashier.dialog_discount.nominal' => 'Nominal (Rp)',
			'cashier.dialog_discount.hint_percent' => '10',
			'cashier.dialog_discount.hint_nominal' => '5000',
			'cashier.dialog_qty.title' => 'Jumlah Barang',
			'cashier.dialog_qty.title_edit' => 'Ubah Jumlah -',
			'cashier.dialog_qty.qty_label' => 'Jumlah',
			'cashier.dialog_qty.qty_hint' => 'Masukkan jumlah barang',
			'cashier.dialog_qty.btn_add' => 'Tambah',
			'cashier.dialog_debt.title' => 'Bayar Hutang',
			'cashier.dialog_debt.customer_name' => 'Nama Pelanggan',
			'cashier.dialog_debt.customer_hint' => 'Masukkan nama pelanggan',
			'cashier.dialog_pending.title' => 'Simpan Pending',
			'cashier.dialog_pending.customer_required' => 'Nama Pelanggan *',
			'cashier.dialog_pending.notes' => 'Catatan',
			'cashier.dialog_pending.saved_success' => 'Pending disimpan untuk',
			'cashier.dialog_unit.title' => 'Pilih Satuan -',
			'cashier.dialog_print.title' => 'Cetak Struk?',
			'cashier.dialog_print.btn_yes' => 'Ya, Cetak',
			'cashier.dialog_print.btn_no' => 'Tidak',
			'cashier.dialog_print.drawer_failed' => 'Gagal membuka laci otomatis, gunakan kunci manual',
			'product.search_hint' => 'Cari produk...',
			'product.stock_minimum' => 'Stok Minimum',
			'product.add_product' => 'Tambah Produk',
			'product.category_all' => 'Semua',
			'product.category_label' => 'Kategori',
			'product.filter_all' => 'Semua',
			'product.filter_low_stock' => 'Stok Tipis',
			'product.filter_out_of_stock' => 'Habis',
			'product.filter_archived' => 'Arsip',
			'product.count_format' => '{count} produk',
			'product.not_found' => 'Produk "{query}" tidak ditemukan',
			'product.empty' => 'Belum ada produk',
			'product.batch_action' => '{count} dipilih',
			'product.btn_archive' => 'Arsipkan',
			'product.btn_delete' => 'Hapus',
			'product.btn_cancel' => 'Batal',
			'product.dialog_delete_title' => 'Hapus Produk',
			'product.dialog_delete_body' => 'Hapus {count} produk permanen? Tindakan ini tidak bisa dibatalkan.',
			'product.btn_delete_all' => 'Hapus Semua',
			'product.dialog_delete_perm_title' => 'Hapus Produk Permanen?',
			'product.dialog_delete_perm_body' => 'Apakah Anda yakin ingin menghapus produk ini secara permanen? Aksi ini tidak dapat dibatalkan.',
			'product.btn_delete_perm' => 'Hapus Permanen',
			'product.saved_badge' => '✓ Tersimpan!',
			'product.form.section_units' => 'DAFTAR SATUAN ({count})',
			'product.form.btn_add_unit' => 'Tambah Satuan',
			'product.form.btn_calc_cost' => 'Hitung Harga Pokok Dasar',
			'product.form.label_cost' => 'HARGA POKOK',
			'product.form.label_sell' => 'HARGA JUAL',
			'product.form.label_conversion' => 'KONVERSI',
			'product.form.label_profit' => 'LABA',
			'product.form.type_base' => 'SATUAN DASAR',
			'product.form.badge_base' => 'BASE',
			'product.form.conversion_text' => 'Konversi: {value}',
			'product.form.dialog_cost_title' => 'Harga Pokok',
			'product.form.dialog_sell_title' => 'Harga Jual',
			'product.form.btn_save' => 'Simpan',
			'product.form.btn_cancel' => 'Batal',
			'product.form.unit_name_hint' => 'Nama Satuan',
			'product.form.conversion_hint' => 'Konversi',
			'product.form.cost_hint' => 'Harga Pokok (Rp)',
			'product.form.sell_hint' => 'Harga Jual (Rp)',
			'product.form.placeholder_name' => 'BARU',
			'product.form.edit_title' => 'Edit Satuan',
			'product.form.btn_save_unit' => 'Simpan Satuan',
			'product.form.label_laba' => 'Laba',
			_ => null,
		};
	}
}
