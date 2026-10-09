import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const output = join(root, "AppStore", "metadata");
rmSync(output, { recursive: true, force: true });

const common = {
  marketing_url: "https://getborda.app",
  privacy_url: "https://getborda.app/privacy/",
  support_url: "https://getborda.app/support/"
};

const locales = {
  "en-US": {
    name: "Borda: Edge Shelf", subtitle: "Move anything across your Mac", keywords: "shelf,drag,drop,files,clipboard,productivity,workflow,folders,temporary,edge",
    description: `Move files, folders, images, links and text between apps without rearranging your windows.\n\nDrag something to the side of a display and Borda keeps it in a temporary glass shelf. When you need it, move the pointer back to that spot and drag the item into any other app.\n\n• Multiple independent shelves across displays\n• Several items in the same shelf\n• Files, folders, images, links, plain text and rich text\n• Quick Look, Share, ZIP, image resize and OCR\n• Optional clipboard history and watched folders\n• Launch at login and global shortcuts\n• Local storage with no account or cloud\n\nBorda is free. Optional coffees support its continued development but never unlock features.`,
    release_notes: "Borda 1.0 introduces private edge shelves, multiple displays, local actions and eleven interface languages."
  },
  "pt-BR": {
    name: "Borda: Prateleira do Mac", subtitle: "Leve tudo entre os apps", keywords: "prateleira,arrastar,arquivos,clipboard,produtividade,pastas,temporário,lateral,mac",
    description: `Leve arquivos, pastas, imagens, links e textos entre aplicativos sem reorganizar suas janelas.\n\nArraste algo para a lateral de um monitor e o Borda guarda em uma caixa temporária de vidro. Quando precisar, volte o ponteiro àquele ponto e arraste o item para qualquer outro aplicativo.\n\n• Várias caixas independentes em diferentes monitores\n• Vários itens na mesma caixa\n• Arquivos, pastas, imagens, links, texto simples e rico\n• Visualização Rápida, Compartilhar, ZIP, redimensionamento e OCR\n• Histórico opcional do clipboard e pastas observadas\n• Abertura ao iniciar e atalhos globais\n• Armazenamento local, sem conta ou nuvem\n\nO Borda é grátis. Cafés opcionais apoiam o desenvolvimento, mas nunca liberam recursos.`,
    release_notes: "O Borda 1.0 traz caixas privadas nas laterais, múltiplos monitores, ações locais e interface em onze idiomas."
  },
  "es-MX": {
    name: "Borda: Estante lateral", subtitle: "Mueve todo entre tus apps", keywords: "estante,arrastrar,archivos,portapapeles,productividad,carpetas,borde,mac",
    description: `Mueve archivos, carpetas, imágenes, enlaces y texto entre apps sin reorganizar ventanas.\n\nArrastra algo al lateral de una pantalla y Borda lo guarda en una estantería temporal de cristal. Vuelve a ese punto y arrastra el elemento a cualquier otra app.\n\nIncluye varias estanterías, varios monitores, Vista rápida, Compartir, ZIP, cambio de tamaño, OCR, historial opcional del portapapeles, carpetas vigiladas y atajos globales. Todo se almacena localmente, sin cuenta ni nube.\n\nBorda es gratis. Los cafés opcionales apoyan el desarrollo y nunca desbloquean funciones.`,
    release_notes: "Borda 1.0 presenta estanterías privadas en los bordes, acciones locales y once idiomas."
  },
  "zh-Hans": {
    name: "Borda：屏幕边缘架", subtitle: "在 Mac 应用之间轻松移动内容", keywords: "文件,拖放,剪贴板,效率,文件夹,边缘,临时架,Mac",
    description: `无需整理窗口，即可在应用之间移动文件、文件夹、图片、链接和文本。\n\n将内容拖到显示器边缘，Borda 会把它保存在临时玻璃架中。需要时回到同一位置，再将内容拖入任何应用。\n\n支持多个显示器和多个独立架子，以及快速查看、共享、ZIP、图片缩放、OCR、可选剪贴板历史、监视文件夹和全局快捷键。所有内容均保存在本机，无需账户或云服务。\n\nBorda 完全免费。自愿购买咖啡仅用于支持开发，不会解锁任何功能。`,
    release_notes: "Borda 1.0 带来私人屏幕边缘架、本地操作和十一种界面语言。"
  },
  ja: {
    name: "Borda：画面端シェルフ", subtitle: "Macのアプリ間をすばやく移動", keywords: "ファイル,ドラッグ,クリップボード,生産性,フォルダ,画面端,シェルフ,Mac",
    description: `ウインドウを並べ替えずに、ファイル、フォルダ、画像、リンク、テキストをアプリ間で移動できます。\n\nディスプレイの端へドラッグすると、Bordaが一時的なガラスのシェルフに保管します。必要なとき同じ場所に戻り、別のアプリへドラッグするだけです。\n\n複数ディスプレイと複数シェルフ、クイックルック、共有、ZIP、画像サイズ変更、OCR、任意のクリップボード履歴、監視フォルダ、グローバルショートカットに対応。内容はローカルに保存され、アカウントやクラウドは不要です。\n\nBordaは無料です。任意のコーヒー購入は開発支援であり、機能の解除はありません。`,
    release_notes: "Borda 1.0では、プライベートな画面端シェルフ、ローカル操作、11言語に対応しました。"
  },
  "de-DE": {
    name: "Borda: Ablage am Rand", subtitle: "Alles zwischen Apps bewegen", keywords: "ablage,ziehen,dateien,zwischenablage,produktivität,ordner,rand,mac",
    description: `Verschiebe Dateien, Ordner, Bilder, Links und Text zwischen Apps, ohne Fenster neu anzuordnen. Ziehe etwas an den Bildschirmrand und Borda bewahrt es in einer temporären Glasablage auf.\n\nMehrere Ablagen und Displays, Übersicht, Teilen, ZIP, Bildskalierung, OCR, optionaler Zwischenablageverlauf, überwachte Ordner und globale Kurzbefehle. Alles bleibt lokal auf deinem Mac – ohne Konto oder Cloud.\n\nBorda ist kostenlos. Optionale Kaffees unterstützen die Entwicklung und schalten keine Funktionen frei.`,
    release_notes: "Borda 1.0 bringt private Randablagen, lokale Aktionen und elf Sprachen."
  },
  "fr-FR": {
    name: "Borda : étagère latérale", subtitle: "Déplacez tout entre vos apps", keywords: "étagère,glisser,fichiers,presse-papiers,productivité,dossiers,bord,mac",
    description: `Déplacez fichiers, dossiers, images, liens et textes entre les apps sans réorganiser vos fenêtres. Glissez un élément vers le bord de l’écran : Borda le conserve dans une étagère de verre temporaire.\n\nPlusieurs étagères et écrans, Coup d’œil, partage, ZIP, redimensionnement, OCR, historique facultatif du presse-papiers, dossiers surveillés et raccourcis globaux. Tout reste local sur votre Mac, sans compte ni cloud.\n\nBorda est gratuit. Les cafés facultatifs soutiennent le développement sans débloquer de fonctions.`,
    release_notes: "Borda 1.0 propose des étagères privées, des actions locales et onze langues."
  },
  ko: {
    name: "Borda: 화면 가장자리 선반", subtitle: "Mac 앱 사이에서 무엇이든 이동", keywords: "선반,드래그,파일,클립보드,생산성,폴더,가장자리,Mac",
    description: `창을 다시 정리하지 않고 파일, 폴더, 이미지, 링크와 텍스트를 앱 사이에서 이동하세요. 화면 가장자리로 드래그하면 Borda가 임시 유리 선반에 보관합니다.\n\n여러 선반과 디스플레이, 훑어보기, 공유, ZIP, 이미지 크기 조정, OCR, 선택적 클립보드 기록, 감시 폴더와 전역 단축키를 지원합니다. 모든 콘텐츠는 계정이나 클라우드 없이 Mac에만 저장됩니다.\n\nBorda는 무료입니다. 선택적 커피 구매는 개발을 후원하며 기능을 잠금 해제하지 않습니다.`,
    release_notes: "Borda 1.0은 비공개 가장자리 선반, 로컬 작업과 11개 언어를 제공합니다."
  },
  it: {
    name: "Borda: ripiano laterale", subtitle: "Sposta tutto tra le app", keywords: "ripiano,trascina,file,appunti,produttività,cartelle,bordo,mac",
    description: `Sposta file, cartelle, immagini, link e testo tra le app senza riordinare le finestre. Trascina qualcosa sul bordo dello schermo e Borda lo conserva in un ripiano temporaneo di vetro.\n\nPiù ripiani e display, Visualizzazione rapida, Condividi, ZIP, ridimensionamento, OCR, cronologia appunti opzionale, cartelle osservate e scorciatoie globali. Tutto resta sul Mac, senza account o cloud.\n\nBorda è gratuito. I caffè opzionali sostengono lo sviluppo e non sbloccano funzioni.`,
    release_notes: "Borda 1.0 introduce ripiani privati, azioni locali e undici lingue."
  },
  "nl-NL": {
    name: "Borda: plank aan de rand", subtitle: "Verplaats alles tussen apps", keywords: "plank,slepen,bestanden,klembord,productiviteit,mappen,rand,mac",
    description: `Verplaats bestanden, mappen, afbeeldingen, links en tekst tussen apps zonder vensters te herschikken. Sleep iets naar de schermrand en Borda bewaart het op een tijdelijke glazen plank.\n\nMeerdere planken en schermen, Snelle weergave, delen, ZIP, afbeeldingsgrootte, OCR, optionele klembordgeschiedenis, bewaakte mappen en globale sneltoetsen. Alles blijft lokaal op je Mac, zonder account of cloud.\n\nBorda is gratis. Optionele koffies steunen de ontwikkeling en ontgrendelen geen functies.`,
    release_notes: "Borda 1.0 biedt privéplanken, lokale acties en elf talen."
  },
  ru: {
    name: "Borda: полка у края", subtitle: "Всё между приложениями", keywords: "полка,перетаскивание,файлы,буфер,папки,край,mac,продуктивность",
    description: `Перемещайте файлы, папки, изображения, ссылки и текст между приложениями, не переставляя окна. Перетащите объект к краю экрана, и Borda сохранит его на временной стеклянной полке.\n\nНесколько полок и дисплеев, быстрый просмотр, общий доступ, ZIP, изменение размера, OCR, необязательная история буфера, отслеживаемые папки и глобальные сочетания. Всё хранится локально на Mac, без аккаунта и облака.\n\nBorda бесплатна. Необязательная покупка кофе поддерживает разработку и не открывает функции.`,
    release_notes: "Borda 1.0 предлагает личные полки у края, локальные действия и одиннадцать языков."
  }
};

for (const [locale, metadata] of Object.entries(locales)) {
  const directory = join(output, locale);
  mkdirSync(directory, { recursive: true });
  for (const [key, value] of Object.entries({ ...common, ...metadata })) {
    writeFileSync(join(directory, `${key}.txt`), `${value.trim()}\n`);
  }
}
console.log(`Generated App Store metadata for ${Object.keys(locales).length} locales.`);
