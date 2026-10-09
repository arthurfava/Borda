import { cpSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const output = join(here, "dist");
function publicHTTPSURL(name) {
  const rawValue = process.env[name]?.trim() ?? "";
  if (!rawValue) return "";
  const parsedDownloadURL = new URL(rawValue);
  if (parsedDownloadURL.protocol !== "https:" || parsedDownloadURL.username || parsedDownloadURL.password) {
    throw new Error(`${name} must be a public HTTPS URL without credentials.`);
  }
  return parsedDownloadURL.href;
}
const downloadURL = publicHTTPSURL("BORDA_DOWNLOAD_URL");
const coffeeURL = publicHTTPSURL("BORDA_COFFEE_URL");
const githubURL = publicHTTPSURL("BORDA_GITHUB_URL");
const downloadChannel = process.env.BORDA_DOWNLOAD_CHANNEL?.trim() || "stable";
if (!["stable", "beta"].includes(downloadChannel)) {
  throw new Error("BORDA_DOWNLOAD_CHANNEL must be stable or beta.");
}
rmSync(output, { recursive: true, force: true });
mkdirSync(join(output, "assets"), { recursive: true });
cpSync(join(here, "assets", "site.css"), join(output, "assets", "site.css"));
cpSync(join(here, "assets", "motion.css"), join(output, "assets", "motion.css"));
cpSync(join(here, "assets", "site.js"), join(output, "assets", "site.js"));
cpSync(join(here, "assets", "borda.png"), join(output, "assets", "borda.png"));

const locales = {
  en: {
    name: "English", lang: "en", route: "", title: "Borda — Move anything across your Mac",
    description: "A private edge shelf for files, folders, images, links and text on macOS.",
    eyebrow: "A faster path across your Mac", headline: "Put it on the edge. Pick it up anywhere.",
    intro: "Borda turns the sides of your displays into quiet temporary shelves. Drag something in, keep working, then drag it out exactly where you need it.",
    download: "Download free", coffee: "Buy me a coffee", source: "View source",
    how: "Three movements. No window juggling.", step1: "Drag to an edge", step1b: "Any file, folder, image, link or piece of text.",
    step2: "Keep it in sight", step2b: "A small glass tab remembers where each shelf lives.", step3: "Drop it anywhere", step3b: "Open the shelf and drag the item into another app.",
    local: "Private by default", localb: "Your content stays on your Mac. Borda has no account, cloud sync or analytics.",
    free: "Free means free", freeb: "Every feature is available without payment. If Borda saves you time, you can choose what that was worth.",
    requirement: "Requires macOS 15 or later", direct: "Direct download",
    open: "Open source", openb: "Inspect the code, report an issue or contribute on GitHub.",
    final: "A tiny shelf for the gap between here and there.", finalb: "Download Borda for free. Keep it if it helps. Support it if you feel like it.",
    privacy: "Privacy", support: "Support", releases: "Releases", terms: "MIT License", language: "Language"
  },
  "pt-br": {
    name: "Português (Brasil)", lang: "pt-BR", route: "pt-br", title: "Borda — Leve qualquer coisa pelo seu Mac",
    description: "Uma prateleira privada na lateral do Mac para arquivos, pastas, imagens, links e textos.",
    eyebrow: "Um caminho mais curto pelo seu Mac", headline: "Deixe na borda. Pegue onde precisar.",
    intro: "O Borda transforma as laterais dos monitores em prateleiras temporárias e discretas. Arraste algo para dentro, continue trabalhando e leve para o destino quando quiser.",
    download: "Baixar grátis", coffee: "Pague um café", source: "Ver código",
    how: "Três movimentos. Nenhuma dança de janelas.", step1: "Arraste para a lateral", step1b: "Arquivo, pasta, imagem, link ou trecho de texto.",
    step2: "Mantenha à vista", step2b: "Uma pequena aba de vidro lembra onde cada caixa está.", step3: "Solte em qualquer lugar", step3b: "Abra a caixa e arraste o item para outro aplicativo.",
    local: "Privado por padrão", localb: "Seu conteúdo fica no seu Mac. O Borda não tem conta, nuvem nem analytics.",
    free: "Grátis de verdade", freeb: "Todos os recursos ficam disponíveis sem pagamento. Se o Borda poupar seu tempo, você decide quanto isso valeu.",
    requirement: "Requer macOS 15 ou posterior", direct: "Download direto",
    open: "Código aberto", openb: "Inspecione o código, relate um problema ou contribua pelo GitHub.",
    final: "Uma pequena prateleira entre o aqui e o lá.", finalb: "Baixe o Borda de graça. Use se ajudar. Apoie se tiver vontade.",
    privacy: "Privacidade", support: "Suporte", releases: "Versões", terms: "Licença MIT", language: "Idioma"
  },
  es: {
    name: "Español", lang: "es", route: "es", title: "Borda — Mueve cualquier cosa por tu Mac", description: "Una estantería privada en el borde para archivos, carpetas, imágenes, enlaces y texto.", eyebrow: "Un camino más corto por tu Mac", headline: "Déjalo en el borde. Recógelo donde quieras.", intro: "Borda convierte los laterales de tus pantallas en estanterías temporales y discretas. Arrastra algo, sigue trabajando y llévalo a su destino cuando quieras.", download: "Descargar gratis", coffee: "Invítame a un café", source: "Ver código", how: "Tres movimientos. Sin reorganizar ventanas.", step1: "Arrastra al borde", step1b: "Archivos, carpetas, imágenes, enlaces o texto.", step2: "Déjalo a la vista", step2b: "Una pequeña pestaña de cristal recuerda cada estantería.", step3: "Suéltalo donde quieras", step3b: "Abre la estantería y arrastra el elemento a otra app.", local: "Privado por defecto", localb: "Tu contenido permanece en tu Mac. Sin cuenta, nube ni analítica.", free: "Gratis de verdad", freeb: "Todas las funciones son gratuitas. Si Borda te ahorra tiempo, tú decides cuánto vale.", requirement: "Requiere macOS 15 o posterior", direct: "Descarga directa", open: "Código abierto", openb: "Revisa el código, informa de un problema o contribuye en GitHub.", final: "Una pequeña estantería entre aquí y allí.", finalb: "Descarga Borda gratis. Úsalo si te ayuda. Apóyalo si quieres.", privacy: "Privacidad", support: "Soporte", releases: "Versiones", terms: "Licencia MIT", language: "Idioma"
  },
  "zh-hans": {
    name: "简体中文", lang: "zh-Hans", route: "zh-hans", title: "Borda — 在 Mac 上轻松移动任何内容", description: "位于屏幕边缘的私人临时架，可存放文件、文件夹、图片、链接和文本。", eyebrow: "让内容在 Mac 上走更短的路", headline: "放到边缘，需要时随手取回。", intro: "Borda 将显示器两侧变成安静的临时架。拖入内容后继续工作，需要时再拖到目标位置。", download: "免费下载", coffee: "请我喝杯咖啡", source: "查看源码", how: "三个动作，无需整理窗口。", step1: "拖到屏幕边缘", step1b: "支持文件、文件夹、图片、链接和文本。", step2: "保持可见", step2b: "小巧的玻璃标签会记住每个架子的位置。", step3: "拖放到任意位置", step3b: "打开架子，将内容拖入其他应用。", local: "默认保护隐私", localb: "内容只保存在你的 Mac 上。无需账户、云同步或分析追踪。", free: "真正免费", freeb: "所有功能均免费。如果 Borda 为你节省了时间，你可以自行决定支持金额。", requirement: "需要 macOS 15 或更高版本", direct: "直接下载", open: "开源", openb: "在 GitHub 查看代码、报告问题或参与贡献。", final: "连接此处与彼处的一小块架子。", finalb: "免费下载 Borda。有帮助就留下，愿意的话再支持。", privacy: "隐私", support: "支持", releases: "版本", terms: "MIT 许可证", language: "语言"
  },
  ja: {
    name: "日本語", lang: "ja", route: "ja", title: "Borda — Mac上のものを軽やかに移動", description: "ファイル、フォルダ、画像、リンク、テキストを置けるプライベートな画面端シェルフ。", eyebrow: "Macの中をもっと短い距離で", headline: "端に置いて、必要な場所で取り出す。", intro: "Bordaはディスプレイの端を静かな一時シェルフに変えます。ドラッグして作業を続け、必要な場所へ取り出せます。", download: "無料ダウンロード", coffee: "コーヒーで応援", source: "ソースを見る", how: "3つの動き。ウインドウ整理は不要。", step1: "端へドラッグ", step1b: "ファイル、フォルダ、画像、リンク、テキストに対応。", step2: "見える場所に保管", step2b: "小さなガラスタブが各シェルフの場所を覚えます。", step3: "どこへでもドロップ", step3b: "シェルフを開き、別のアプリへドラッグします。", local: "初めからプライベート", localb: "内容はMac内に保存。アカウント、クラウド同期、解析はありません。", free: "本当に無料", freeb: "すべての機能を無料で利用できます。役立った分だけ自由に応援できます。", requirement: "macOS 15以降が必要", direct: "直接ダウンロード", open: "オープンソース", openb: "GitHubでコード確認、問題報告、貢献ができます。", final: "ここからそこまでの、小さなシェルフ。", finalb: "Bordaは無料です。役立ったら使い続け、よければ応援してください。", privacy: "プライバシー", support: "サポート", releases: "リリース", terms: "MITライセンス", language: "言語"
  },
  de: {
    name: "Deutsch", lang: "de", route: "de", title: "Borda — Alles mühelos auf deinem Mac bewegen", description: "Eine private Ablage am Bildschirmrand für Dateien, Ordner, Bilder, Links und Text.", eyebrow: "Der kürzere Weg durch deinen Mac", headline: "Am Rand ablegen. Überall wieder aufnehmen.", intro: "Borda verwandelt die Seiten deiner Displays in ruhige temporäre Ablagen. Hineinziehen, weiterarbeiten und später am Ziel wieder herausziehen.", download: "Kostenlos laden", coffee: "Einen Kaffee spendieren", source: "Quellcode ansehen", how: "Drei Bewegungen. Kein Fensterchaos.", step1: "Zum Rand ziehen", step1b: "Dateien, Ordner, Bilder, Links oder Text.", step2: "Im Blick behalten", step2b: "Ein kleiner Glasreiter merkt sich jede Ablage.", step3: "Überall ablegen", step3b: "Ablage öffnen und das Element in eine andere App ziehen.", local: "Standardmäßig privat", localb: "Deine Inhalte bleiben auf deinem Mac. Kein Konto, keine Cloud, keine Analyse.", free: "Wirklich kostenlos", freeb: "Alle Funktionen sind kostenlos. Wenn Borda Zeit spart, bestimmst du den Wert.", requirement: "Benötigt macOS 15 oder neuer", direct: "Direkter Download", open: "Open Source", openb: "Code prüfen, Fehler melden oder auf GitHub beitragen.", final: "Eine kleine Ablage zwischen hier und dort.", finalb: "Borda kostenlos laden. Behalten, wenn es hilft. Unterstützen, wenn du möchtest.", privacy: "Datenschutz", support: "Support", releases: "Versionen", terms: "MIT-Lizenz", language: "Sprache"
  },
  fr: {
    name: "Français", lang: "fr", route: "fr", title: "Borda — Déplacez tout sur votre Mac", description: "Une étagère privée au bord de l’écran pour fichiers, dossiers, images, liens et texte.", eyebrow: "Un chemin plus court dans votre Mac", headline: "Posez-le sur le bord. Reprenez-le où vous voulez.", intro: "Borda transforme les côtés de vos écrans en étagères temporaires discrètes. Déposez, continuez à travailler, puis récupérez au bon endroit.", download: "Télécharger gratuitement", coffee: "M’offrir un café", source: "Voir le code", how: "Trois gestes. Aucune fenêtre à réorganiser.", step1: "Glissez vers le bord", step1b: "Fichier, dossier, image, lien ou texte.", step2: "Gardez-le en vue", step2b: "Un petit onglet de verre mémorise chaque étagère.", step3: "Déposez n’importe où", step3b: "Ouvrez l’étagère et glissez l’élément dans une autre app.", local: "Privé par défaut", localb: "Vos contenus restent sur votre Mac. Aucun compte, cloud ou outil d’analyse.", free: "Vraiment gratuit", freeb: "Toutes les fonctions sont gratuites. Si Borda vous fait gagner du temps, vous choisissez sa valeur.", requirement: "Nécessite macOS 15 ou ultérieur", direct: "Téléchargement direct", open: "Open source", openb: "Consultez le code, signalez un problème ou contribuez sur GitHub.", final: "Une petite étagère entre ici et là-bas.", finalb: "Téléchargez Borda gratuitement. Gardez-le s’il aide. Soutenez-le si vous le souhaitez.", privacy: "Confidentialité", support: "Assistance", releases: "Versions", terms: "Licence MIT", language: "Langue"
  },
  ko: {
    name: "한국어", lang: "ko", route: "ko", title: "Borda — Mac의 모든 항목을 간편하게 이동", description: "파일, 폴더, 이미지, 링크와 텍스트를 위한 비공개 화면 가장자리 선반입니다.", eyebrow: "Mac 안에서 더 짧은 이동 경로", headline: "가장자리에 두고, 필요한 곳에서 꺼내세요.", intro: "Borda는 디스플레이 양옆을 조용한 임시 선반으로 바꿉니다. 항목을 넣고 작업을 계속한 뒤 원하는 곳으로 다시 드래그하세요.", download: "무료 다운로드", coffee: "커피로 응원하기", source: "소스 보기", how: "세 번의 움직임. 창 정리는 필요 없습니다.", step1: "가장자리로 드래그", step1b: "파일, 폴더, 이미지, 링크 또는 텍스트.", step2: "눈에 보이게 보관", step2b: "작은 유리 탭이 각 선반의 위치를 기억합니다.", step3: "어디든 놓기", step3b: "선반을 열고 다른 앱으로 항목을 드래그합니다.", local: "기본적으로 비공개", localb: "콘텐츠는 Mac에만 저장됩니다. 계정, 클라우드, 분석 기능이 없습니다.", free: "완전히 무료", freeb: "모든 기능이 무료입니다. 시간을 아껴줬다면 원하는 만큼 후원할 수 있습니다.", requirement: "macOS 15 이상 필요", direct: "직접 다운로드", open: "오픈 소스", openb: "GitHub에서 코드를 확인하고 문제를 알리거나 기여하세요.", final: "여기와 저기 사이의 작은 선반.", finalb: "Borda를 무료로 받으세요. 도움이 된다면 사용하고, 원한다면 후원하세요.", privacy: "개인정보 보호", support: "지원", releases: "릴리스", terms: "MIT 라이선스", language: "언어"
  },
  it: {
    name: "Italiano", lang: "it", route: "it", title: "Borda — Sposta qualsiasi cosa sul tuo Mac", description: "Un ripiano privato sul bordo per file, cartelle, immagini, link e testo.", eyebrow: "La strada più breve nel tuo Mac", headline: "Lascialo sul bordo. Riprendilo ovunque.", intro: "Borda trasforma i lati dei display in ripiani temporanei discreti. Trascina qualcosa, continua a lavorare e riprendilo dove serve.", download: "Scarica gratis", coffee: "Offrimi un caffè", source: "Vedi il codice", how: "Tre movimenti. Nessuna giostra di finestre.", step1: "Trascina sul bordo", step1b: "File, cartelle, immagini, link o testo.", step2: "Tienilo in vista", step2b: "Una piccola linguetta di vetro ricorda ogni ripiano.", step3: "Rilascia ovunque", step3b: "Apri il ripiano e trascina l’elemento in un’altra app.", local: "Privato per impostazione predefinita", localb: "I contenuti restano sul Mac. Nessun account, cloud o analisi.", free: "Gratis davvero", freeb: "Tutte le funzioni sono gratuite. Se Borda ti fa risparmiare tempo, decidi tu quanto vale.", requirement: "Richiede macOS 15 o successivo", direct: "Download diretto", open: "Open source", openb: "Controlla il codice, segnala problemi o contribuisci su GitHub.", final: "Un piccolo ripiano tra qui e lì.", finalb: "Scarica Borda gratis. Tienilo se aiuta. Sostienilo se vuoi.", privacy: "Privacy", support: "Supporto", releases: "Versioni", terms: "Licenza MIT", language: "Lingua"
  },
  nl: {
    name: "Nederlands", lang: "nl", route: "nl", title: "Borda — Verplaats alles moeiteloos op je Mac", description: "Een privéplank aan de schermrand voor bestanden, mappen, afbeeldingen, links en tekst.", eyebrow: "De kortere route door je Mac", headline: "Zet het aan de rand. Pak het overal weer op.", intro: "Borda verandert de zijkanten van je schermen in rustige tijdelijke planken. Sleep iets erin, werk verder en haal het tevoorschijn waar je het nodig hebt.", download: "Gratis downloaden", coffee: "Trakteer me op koffie", source: "Bekijk de code", how: "Drie bewegingen. Geen gedoe met vensters.", step1: "Sleep naar de rand", step1b: "Bestand, map, afbeelding, link of tekst.", step2: "Houd het in beeld", step2b: "Een klein glazen lipje onthoudt elke plank.", step3: "Zet het overal neer", step3b: "Open de plank en sleep het item naar een andere app.", local: "Standaard privé", localb: "Je inhoud blijft op je Mac. Geen account, cloud of analytics.", free: "Echt gratis", freeb: "Alle functies zijn gratis. Als Borda tijd bespaart, bepaal jij wat dat waard is.", requirement: "Vereist macOS 15 of nieuwer", direct: "Directe download", open: "Open source", openb: "Bekijk de code, meld een probleem of draag bij op GitHub.", final: "Een kleine plank tussen hier en daar.", finalb: "Download Borda gratis. Gebruik het als het helpt. Steun het als je wilt.", privacy: "Privacy", support: "Ondersteuning", releases: "Versies", terms: "MIT-licentie", language: "Taal"
  },
  ru: {
    name: "Русский", lang: "ru", route: "ru", title: "Borda — Перемещайте что угодно на Mac", description: "Личная полка у края экрана для файлов, папок, изображений, ссылок и текста.", eyebrow: "Короткий путь по вашему Mac", headline: "Оставьте у края. Заберите где угодно.", intro: "Borda превращает края дисплеев в незаметные временные полки. Перетащите объект, продолжайте работу и заберите его в нужном месте.", download: "Скачать бесплатно", coffee: "Угостить кофе", source: "Посмотреть код", how: "Три движения. Без перестановки окон.", step1: "Перетащите к краю", step1b: "Файл, папку, изображение, ссылку или текст.", step2: "Оставьте на виду", step2b: "Маленькая стеклянная вкладка помнит каждую полку.", step3: "Перетащите куда угодно", step3b: "Откройте полку и перенесите объект в другое приложение.", local: "Конфиденциально по умолчанию", localb: "Данные остаются на вашем Mac. Без аккаунта, облака и аналитики.", free: "Действительно бесплатно", freeb: "Все функции бесплатны. Если Borda экономит ваше время, вы сами выбираете сумму поддержки.", requirement: "Требуется macOS 15 или новее", direct: "Прямая загрузка", open: "Открытый код", openb: "Изучайте код, сообщайте об ошибках и участвуйте в GitHub.", final: "Маленькая полка между здесь и там.", finalb: "Скачайте Borda бесплатно. Пользуйтесь, если помогает. Поддержите, если хотите.", privacy: "Конфиденциальность", support: "Поддержка", releases: "Версии", terms: "Лицензия MIT", language: "Язык"
  }
};

const installGuides = {
  en: { label: "Installation", title: "From download to your edge in a minute.", one: "Download the DMG", oneb: "Open the disk image after the download finishes.", two: "Drag Borda to Applications", twob: "Use the Applications shortcut shown in the installer window.", three: "Open Borda", threeb: "Borda appears in the menu bar and can start automatically with your Mac." },
  "pt-br": { label: "Instalação", title: "Do download à sua lateral em um minuto.", one: "Baixe o DMG", oneb: "Abra a imagem de disco quando o download terminar.", two: "Arraste para Aplicativos", twob: "Use o atalho Aplicativos exibido na janela de instalação.", three: "Abra o Borda", threeb: "O Borda aparece na barra de menus e pode iniciar automaticamente com o Mac." },
  es: { label: "Instalación", title: "De la descarga al borde en un minuto.", one: "Descarga el DMG", oneb: "Abre la imagen de disco al terminar la descarga.", two: "Arrastra a Aplicaciones", twob: "Usa el acceso a Aplicaciones de la ventana de instalación.", three: "Abre Borda", threeb: "Borda aparece en la barra de menús y puede iniciarse con tu Mac." },
  "zh-hans": { label: "安装", title: "一分钟即可从下载到屏幕边缘。", one: "下载 DMG", oneb: "下载完成后打开磁盘映像。", two: "拖入应用程序", twob: "使用安装窗口中的“应用程序”快捷方式。", three: "打开 Borda", threeb: "Borda 会出现在菜单栏中，并可随 Mac 自动启动。" },
  ja: { label: "インストール", title: "ダウンロードから画面端まで、約1分。", one: "DMGをダウンロード", oneb: "完了したらディスクイメージを開きます。", two: "アプリケーションへ移動", twob: "インストーラのショートカットへBordaをドラッグします。", three: "Bordaを開く", threeb: "メニューバーに表示され、Macと同時に起動できます。" },
  de: { label: "Installation", title: "In einer Minute vom Download an den Rand.", one: "DMG laden", oneb: "Öffne das Image nach dem Download.", two: "Nach Programme ziehen", twob: "Nutze die Verknüpfung im Installationsfenster.", three: "Borda öffnen", threeb: "Borda erscheint in der Menüleiste und kann mit dem Mac starten." },
  fr: { label: "Installation", title: "Du téléchargement au bord de l’écran en une minute.", one: "Téléchargez le DMG", oneb: "Ouvrez l’image disque une fois téléchargée.", two: "Glissez dans Applications", twob: "Utilisez le raccourci de la fenêtre d’installation.", three: "Ouvrez Borda", threeb: "Borda apparaît dans la barre des menus et peut démarrer avec le Mac." },
  ko: { label: "설치", title: "다운로드부터 화면 가장자리까지 1분이면 됩니다.", one: "DMG 다운로드", oneb: "다운로드가 끝나면 디스크 이미지를 여세요.", two: "응용 프로그램으로 드래그", twob: "설치 창의 응용 프로그램 바로가기를 사용하세요.", three: "Borda 열기", threeb: "메뉴 막대에 나타나며 Mac 시작 시 자동 실행할 수 있습니다." },
  it: { label: "Installazione", title: "Dal download al bordo in un minuto.", one: "Scarica il DMG", oneb: "Apri l’immagine disco al termine del download.", two: "Trascina in Applicazioni", twob: "Usa il collegamento nella finestra di installazione.", three: "Apri Borda", threeb: "Borda appare nella barra menu e può avviarsi con il Mac." },
  nl: { label: "Installatie", title: "Van download naar je schermrand in één minuut.", one: "Download de DMG", oneb: "Open de schijfkopie zodra de download klaar is.", two: "Sleep naar Apps", twob: "Gebruik de snelkoppeling in het installatievenster.", three: "Open Borda", threeb: "Borda verschijnt in de menubalk en kan met je Mac opstarten." },
  ru: { label: "Установка", title: "От загрузки до края экрана за минуту.", one: "Скачайте DMG", oneb: "Откройте образ диска после загрузки.", two: "Перетащите в Программы", twob: "Используйте ярлык в окне установки.", three: "Откройте Borda", threeb: "Borda появится в строке меню и сможет запускаться вместе с Mac." }
};

const directDescriptions = {
  en: "Independent DMG download for macOS. No account or subscription required.",
  "pt-br": "DMG independente para macOS. Sem conta ou assinatura obrigatória.",
  es: "DMG independiente para macOS. Sin cuenta ni suscripción obligatoria.",
  "zh-hans": "面向 macOS 的独立 DMG 下载，无需账户或订阅。",
  ja: "macOS向けの独立DMG。アカウントやサブスクリプションは不要です。",
  de: "Unabhängiger DMG-Download für macOS. Kein Konto oder Abo nötig.",
  fr: "DMG indépendant pour macOS. Aucun compte ni abonnement requis.",
  ko: "macOS용 독립 DMG 다운로드입니다. 계정이나 구독이 필요하지 않습니다.",
  it: "Download DMG indipendente per macOS. Nessun account o abbonamento richiesto.",
  nl: "Onafhankelijke DMG-download voor macOS. Geen account of abonnement nodig.",
  ru: "Независимый DMG для macOS. Аккаунт и подписка не требуются."
};

const motionLabels = {
  en: ["Drag to the edge", "Keep it for later", "Take it anywhere"],
  "pt-br": ["Arraste para a lateral", "Deixe para depois", "Leve para qualquer lugar"],
  es: ["Arrastra al borde", "Guárdalo para después", "Llévalo a cualquier lugar"],
  "zh-hans": ["拖到屏幕边缘", "暂时存放", "随处取用"],
  ja: ["端へドラッグ", "あとで使う", "どこへでも移動"],
  de: ["Zum Rand ziehen", "Für später ablegen", "Überallhin mitnehmen"],
  fr: ["Glissez vers le bord", "Gardez pour plus tard", "Déposez où vous voulez"],
  ko: ["가장자리로 드래그", "나중을 위해 보관", "어디든 가져가기"],
  it: ["Trascina sul bordo", "Conserva per dopo", "Portalo ovunque"],
  nl: ["Sleep naar de rand", "Bewaar voor later", "Neem overal mee"],
  ru: ["Перетащите к краю", "Оставьте на потом", "Перенесите куда угодно"]
};

const escape = value => value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
const canonical = locale => `https://getborda.app/${locale.route ? `${locale.route}/` : ""}`;
const navOptions = current => Object.values(locales).map(locale => `<option value="/${locale.route ? `${locale.route}/` : ""}"${locale === current ? " selected" : ""}>${locale.name}</option>`).join("");
const alternateLinks = Object.values(locales).map(locale => `<link rel="alternate" hreflang="${locale.lang}" href="${canonical(locale)}">`).join("\n");

function page(locale) {
  const guide = installGuides[locale.route || "en"];
  const directDescription = directDescriptions[locale.route || "en"];
  const motion = motionLabels[locale.route || "en"];
  const jsonLd = JSON.stringify({ "@context": "https://schema.org", "@type": "SoftwareApplication", name: "Borda", applicationCategory: "UtilitiesApplication", operatingSystem: "macOS 15+", offers: { "@type": "Offer", price: "0", priceCurrency: "USD" }, downloadUrl: "https://getborda.app/download/", softwareVersion: "0.9.0", description: locale.description });
  return `<!doctype html>
<html lang="${locale.lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escape(locale.title)}</title><meta name="description" content="${escape(locale.description)}"><link rel="canonical" href="${canonical(locale)}">
${alternateLinks}<link rel="alternate" hreflang="x-default" href="https://getborda.app/">
<meta property="og:type" content="website"><meta property="og:title" content="${escape(locale.title)}"><meta property="og:description" content="${escape(locale.description)}"><meta property="og:image" content="https://getborda.app/assets/borda.png"><meta name="theme-color" content="#060b18">
<link rel="icon" href="/assets/borda.png"><link rel="stylesheet" href="/assets/site.css"><link rel="stylesheet" href="/assets/motion.css"><script type="application/ld+json">${jsonLd}</script></head>
<body><header class="nav"><a class="brand" href="/"><img src="/assets/borda.png" alt=""><span>Borda</span></a><div class="nav-actions"><label class="language"><span class="sr-only">${escape(locale.language)}</span><select data-language>${navOptions(locale)}</select></label><a href="/github/">GitHub</a></div></header>
<main><section class="hero"><div class="hero-copy"><p class="eyebrow">${escape(locale.eyebrow)}</p><h1>${escape(locale.headline)}</h1><p class="lede">${escape(locale.intro)}</p><div class="actions"><a class="button primary" href="/download/" data-download>${escape(locale.download)}</a><a class="button coffee" href="/cafe/">☕ ${escape(locale.coffee)}</a></div><div class="quiet-actions"><a href="#install">${escape(guide.label)} ↓</a><a href="/github/">${escape(locale.source)} ↗</a></div><p class="requirement"> ${escape(locale.requirement)}</p></div>
<div class="product-scene" data-motion-demo aria-label="Borda preview"><div class="screen"><div class="edge-signal" aria-hidden="true"></div><div class="file-chip" aria-hidden="true"><span>⌁</span> campaign-brief.pdf</div><div class="demo-cursor" aria-hidden="true"><svg viewBox="0 0 28 34"><path d="M3 2 24 21l-10 1 5 9-5 2-5-9-7 7z"/></svg></div><div class="edge-shelf"><div class="shelf-head"><b>Borda</b><span>3</span></div><div class="shelf-row"><i>PDF</i><span>campaign-brief.pdf<small>PDF · 4.8 MB</small></span></div><div class="shelf-row"><i>IMG</i><span>moodboard.png<small>Image · 2.1 MB</small></span></div><div class="shelf-row"><i>TXT</i><span>Idea for later<small>Text · 84 B</small></span></div></div><div class="motion-captions" aria-hidden="true"><span>${escape(motion[0])}</span><span>${escape(motion[1])}</span><span>${escape(motion[2])}</span></div><button class="motion-replay" type="button" data-motion-replay aria-label="Replay animation">↻</button></div></div></section>
<section class="workflow"><p class="eyebrow">Borda</p><h2>${escape(locale.how)}</h2><div class="steps"><article><span>01</span><h3>${escape(locale.step1)}</h3><p>${escape(locale.step1b)}</p></article><article><span>02</span><h3>${escape(locale.step2)}</h3><p>${escape(locale.step2b)}</p></article><article><span>03</span><h3>${escape(locale.step3)}</h3><p>${escape(locale.step3b)}</p></article></div></section>
<section class="principles"><article><div class="glyph">⌂</div><h2>${escape(locale.local)}</h2><p>${escape(locale.localb)}</p></article><article><div class="glyph">∞</div><h2>${escape(locale.free)}</h2><p>${escape(locale.freeb)}</p><a href="/cafe/">${escape(locale.coffee)} ↗</a></article></section>
<section class="installation" id="install"><p class="eyebrow">${escape(guide.label)}</p><h2>${escape(guide.title)}</h2><div class="install-steps"><article><span>1</span><div><h3>${escape(guide.one)}</h3><p>${escape(guide.oneb)}</p></div></article><article><span>2</span><div><h3>${escape(guide.two)}</h3><p>${escape(guide.twob)}</p></div></article><article><span>3</span><div><h3>${escape(guide.three)}</h3><p>${escape(guide.threeb)}</p></div></article></div></section>
<section class="channels" id="download"><article><p class="eyebrow">DMG</p><h2>${escape(locale.direct)}</h2><p>${escape(directDescription)}</p><a class="button primary" href="/download/" data-download>${escape(locale.download)}</a></article><article><p class="eyebrow">GitHub</p><h2>${escape(locale.open)}</h2><p>${escape(locale.openb)}</p><a class="button secondary" href="/github/">${escape(locale.source)} ↗</a></article></section>
<section class="closing"><img src="/assets/borda.png" alt="Borda"><h2>${escape(locale.final)}</h2><p>${escape(locale.finalb)}</p><div class="actions"><a class="button primary" href="/download/" data-download>${escape(locale.download)}</a><a class="button coffee" href="/cafe/">☕ ${escape(locale.coffee)}</a></div></section></main>
<footer><span>© 2026 Arthur Fava</span><nav><a href="/privacy/">${escape(locale.privacy)}</a><a href="/support/">${escape(locale.support)}</a><a href="/github/">${escape(locale.releases)}</a><a href="/github/">${escape(locale.terms)}</a></nav></footer>
<div class="download-note" data-download-note hidden><button aria-label="Close">×</button><b>${escape(locale.download)}</b><span>${escape(locale.freeb)}</span><a href="/cafe/">☕ ${escape(locale.coffee)}</a></div><script src="/assets/site.js" defer></script></body></html>`;
}

for (const locale of Object.values(locales)) {
  const directory = join(output, locale.route);
  mkdirSync(directory, { recursive: true });
  writeFileSync(join(directory, "index.html"), page(locale));
}

const policy = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Privacy — Borda</title><link rel="stylesheet" href="/assets/site.css"></head><body><header class="nav"><a class="brand" href="/"><img src="/assets/borda.png" alt=""><span>Borda</span></a></header><main class="legal"><p class="eyebrow">Privacy</p><h1>Your files stay yours.</h1><p>Borda stores shelves and their contents locally on your Mac. The app does not require an account and does not collect analytics, advertising identifiers, contacts, location, or the content you place in a shelf.</p><h2>Website</h2><p>This website does not use advertising cookies or behavioral analytics. The hosting provider may process standard technical request logs for security and reliability.</p><h2>Payments</h2><p>Optional support is processed by Buy Me a Coffee. Its own privacy policy applies to those transactions. Borda never receives your full payment details.</p><h2>Contact</h2><p><a href="mailto:support@getborda.app">support@getborda.app</a></p><p>Last updated: October 9, 2026.</p></main></body></html>`;
mkdirSync(join(output, "privacy"), { recursive: true }); writeFileSync(join(output, "privacy", "index.html"), policy);

const support = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Support — Borda</title><link rel="stylesheet" href="/assets/site.css"></head><body><header class="nav"><a class="brand" href="/"><img src="/assets/borda.png" alt=""><span>Borda</span></a></header><main class="legal"><p class="eyebrow">Support</p><h1>How can we help?</h1><p>For help, bug reports or accessibility feedback, email <a href="mailto:support@getborda.app">support@getborda.app</a>.</p><h2>Before writing</h2><p>Confirm that Borda is in the Applications folder, that your Mac runs macOS 15 or later, and include the Borda version shown in Finder.</p><h2>Open source</h2><p>You can also <a href="/github/">open an issue on GitHub</a> once the public repository is available. Never attach private files from your Borda vault.</p></main></body></html>`;
mkdirSync(join(output, "support"), { recursive: true }); writeFileSync(join(output, "support", "index.html"), support);

const download = downloadURL
  ? downloadChannel === "beta"
    ? `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>Borda public beta</title><link rel="stylesheet" href="/assets/site.css"></head><body><main class="legal"><img class="download-icon" src="/assets/borda.png" alt="Borda"><p class="eyebrow">Public beta · 0.9.0</p><h1>Try Borda before the signed release.</h1><p>This beta is not yet signed with an Apple Developer ID or notarized. macOS may block it or require an explicit security exception. If you prefer a frictionless installation, wait for the signed release.</p><p><a class="button primary" href="${downloadURL}">Download the unnotarized beta</a></p><p>SHA-256: <code>b03fa934f745a28008fd5fca43e0e20e6c35ddf79704ab9353317bff33e1d4ed</code></p><p><a href="/github/">View release notes on GitHub</a>.</p></main></body></html>`
    : `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="0;url=${downloadURL}"><title>Downloading Borda…</title><link rel="stylesheet" href="/assets/site.css"></head><body><main class="legal"><img class="download-icon" src="/assets/borda.png" alt="Borda"><h1>Your download is starting.</h1><p>If it does not begin, <a href="${downloadURL}">download Borda directly</a>.</p><p>Borda is free. If it earns a place in your workflow, <a href="/cafe/">you can buy Arthur a coffee</a>.</p></main></body></html>`
  : `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Borda download</title><link rel="stylesheet" href="/assets/site.css"></head><body><main class="legal"><img class="download-icon" src="/assets/borda.png" alt="Borda"><p class="eyebrow">Public beta</p><h1>The signed download is almost ready.</h1><p>The site is live, but the DMG will only be published after Apple Developer signing and notarization are complete. This protects you from installing an unverified build.</p><p>Follow <a href="/github/">Borda on GitHub</a> for the release.</p></main></body></html>`;
mkdirSync(join(output, "download"), { recursive: true }); writeFileSync(join(output, "download", "index.html"), download);

const redirectPage = (title, url, ready, waiting) => url
  ? `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="0;url=${url}"><meta name="robots" content="noindex"><title>${title}</title><link rel="stylesheet" href="/assets/site.css"></head><body><main class="legal"><img class="download-icon" src="/assets/borda.png" alt="Borda"><h1>${ready}</h1><p><a href="${url}">Continue manually</a> if the page does not open.</p></main></body></html>`
  : `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>${title}</title><link rel="stylesheet" href="/assets/site.css"></head><body><main class="legal"><img class="download-icon" src="/assets/borda.png" alt="Borda"><p class="eyebrow">Borda</p><h1>${waiting}</h1><p>This link will become active as soon as the public profile is ready.</p><p><a href="/">Back to Borda</a></p></main></body></html>`;
mkdirSync(join(output, "cafe"), { recursive: true });
writeFileSync(join(output, "cafe", "index.html"), redirectPage("Support Borda", coffeeURL, "Opening the support page…", "The coffee page is almost ready."));
mkdirSync(join(output, "github"), { recursive: true });
writeFileSync(join(output, "github", "index.html"), redirectPage("Borda on GitHub", githubURL, "Opening GitHub…", "The public repository is almost ready."));

writeFileSync(join(output, "robots.txt"), "User-agent: *\nAllow: /\nSitemap: https://getborda.app/sitemap.xml\n");
writeFileSync(join(output, "sitemap.xml"), `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${Object.values(locales).map(locale => `<url><loc>${canonical(locale)}</loc></url>`).join("")}<url><loc>https://getborda.app/privacy/</loc></url><url><loc>https://getborda.app/support/</loc></url><url><loc>https://getborda.app/download/</loc></url></urlset>`);
mkdirSync(join(output, "releases"), { recursive: true });
writeFileSync(join(output, "releases", "latest.json"), JSON.stringify({ version: "0.9.0", build: 90, channel: downloadChannel, notarized: downloadChannel === "stable" && Boolean(downloadURL), available: Boolean(downloadURL), url: downloadURL || null }, null, 2));
