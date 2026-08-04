import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"

    static let storageKey = "vibes-yall.app-language"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            "English"
        case .spanish:
            "Español"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

@MainActor
final class AppLanguageStore: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.storageKey)
        }
    }

    init() {
        let savedValue = UserDefaults.standard.string(forKey: AppLanguage.storageKey)
        language = AppLanguage(rawValue: savedValue ?? "") ?? .english
    }
}

enum L10n {
    static var language: AppLanguage {
        let savedValue = UserDefaults.standard.string(forKey: AppLanguage.storageKey)
        return AppLanguage(rawValue: savedValue ?? "") ?? .english
    }

    static func string(_ english: String) -> String {
        guard language == .spanish else { return english }
        return spanish[english] ?? english
    }

    static func format(_ english: String, _ arguments: CVarArg...) -> String {
        String(format: string(english), locale: language.locale, arguments: arguments)
    }

    static func count(_ count: Int, singular: String, plural: String) -> String {
        format(count == 1 ? singular : plural, count)
    }

    static func serverMessage(_ message: String) -> String {
        string(message)
    }

    static func category(_ value: String) -> String {
        string(value)
    }

    private static let spanish: [String: String] = [
        // Vibes. These English values remain the canonical API/database values.
        "Changed my Life": "Me cambió la vida",
        "Fire": "Está brutal",
        "Worth the Drive": "Vale el viaje",
        "Iconic": "Icónico",
        "Hidden Gem": "Joya escondida",
        "Underrated": "Muy subestimado",
        "Bougie": "Muy elegante",
        "Low-key": "Tranqui",
        "Mid": "Meh",
        "Chaos": "Un caos",
        "Overrated": "Sobrevalorado",
        "Tourist Trap": "Trampa para turistas",
        "Needs Prayer": "Que Dios nos ayude",
        "Emotionally Damaging": "Te deja traumado",

        // Compact map/filter labels.
        "Life": "Vida",
        "Drive": "Viaje",
        "Gem": "Joya",
        "Under": "Subestimado",
        "Over": "Sobrevalorado",
        "Trap": "Trampa",
        "Prayer": "Dios",
        "Damaging": "Traumado",

        // App menu and account flows.
        "Language": "Idioma",
        "Map-first place vibes. No account needed to explore or submit.": "Descubre lugares por su vibra. No necesitas una cuenta para explorar o enviar.",
        "Close menu": "Cerrar menú",
        "Account saved": "Cuenta guardada",
        "Create or sign in": "Crear cuenta o iniciar sesión",
        "Your confirmed account is active on this device.": "Tu cuenta confirmada está activa en este dispositivo.",
        "Email links only. No password needed.": "Solo enlaces por correo. No necesitas contraseña.",
        "Log out": "Cerrar sesión",
        "Keep using the map anonymously on this device.": "Sigue usando el mapa de forma anónima en este dispositivo.",
        "Privacy Policy": "Política de privacidad",
        "Terms of Use": "Términos de uso",
        "Support": "Ayuda",
        "Delete account": "Eliminar cuenta",
        "Delete the optional account tied to this device and email.": "Elimina la cuenta opcional vinculada a este dispositivo y correo.",
        "Sign in": "Iniciar sesión",
        "Save your vibes": "Guarda tus vibes",
        "No password needed. We'll email a secure sign-in link.": "No necesitas contraseña. Te enviaremos un enlace seguro por correo.",
        "Sent": "Enviado",
        "Send sign-in link": "Enviar enlace de acceso",
        "Send confirmation": "Enviar confirmación",
        "Email address": "Correo electrónico",
        "Maybe later": "Quizás después",
        "Done": "Listo",
        "Check your email, tap the sign-in link, then return here.": "Revisa tu correo, toca el enlace para iniciar sesión y vuelve aquí.",
        "Check your email, confirm the link, then return here. We'll finish setup automatically.": "Revisa tu correo, confirma el enlace y vuelve aquí. Terminaremos la configuración automáticamente.",
        "This removes the optional email account linked to this device. Anonymous vibe events remain private and continue to count only in aggregate place stats.": "Esto elimina la cuenta de correo opcional vinculada a este dispositivo. Tus vibes anónimas siguen siendo privadas y solo cuentan en las estadísticas generales de los lugares.",
        "Deleted": "Eliminada",
        "Cancel": "Cancelar",
        "Close": "Cerrar",
        "Keep past and future vibes tied to one account.": "Mantén tus vibes pasadas y futuras vinculadas a una cuenta.",
        "Switch devices without losing your place history.": "Cambia de dispositivo sin perder tu historial de lugares.",
        "Edit older vibes when your opinion changes.": "Edita vibes anteriores cuando cambie tu opinión.",
        "Help keep the map authentic and harder to spam.": "Ayuda a mantener el mapa auténtico y más protegido contra el spam.",

        // Map, search, and nearby discovery.
        "Dark": "Oscuro",
        "Standard": "Estándar",
        "Map": "Mapa",
        "Satellite": "Satélite",
        "Sat": "Sat.",
        "Map style": "Estilo de mapa",
        "My location": "Mi ubicación",
        "Near me": "Cerca de mí",
        "Open VIBES Y'ALL menu": "Abrir menú de VIBES Y'ALL",
        "Search a place...": "Busca un lugar...",
        "Hide keyboard": "Ocultar teclado",
        "Clear search": "Borrar búsqueda",
        "All": "Todo",
        " or ": " o ",
        "No results match those vibes yet.": "Aún no hay resultados con esas vibes.",
        "Clear a chip or try another nearby search.": "Quita un filtro o prueba otra búsqueda cercana.",
        "Related results": "Resultados relacionados",
        "What's Nearby": "Qué hay cerca",
        "My Vibes": "Mis vibes",
        "Nearby": "Cerca",
        "Show nearby discovery": "Mostrar descubrimientos cercanos",
        "Show my vibes in this area": "Mostrar mis vibes en esta zona",
        "Minimize discovery": "Minimizar descubrimientos",
        "Trending in this area": "Tendencias en esta zona",
        "Early Reads": "Primeras impresiones",
        "My Vibes in this area": "Mis vibes en esta zona",
        "Could not load nearby vibes.": "No se pudieron cargar las vibes cercanas.",
        "Try again": "Intentar de nuevo",
        "Show more nearby places": "Mostrar más lugares cercanos",
        "No vibes yet": "Aún no hay vibes",
        "Choose spot": "Elige un lugar",
        "Close spot choices": "Cerrar opciones de lugares",
        "Finding places": "Buscando lugares",
        "Close spot": "Cerrar lugar",
        "Add vibe": "Añadir vibe",
        "Edit vibes": "Editar vibes",

        // Discovery signals.
        "Be first": "Sé el primero",
        "Early Read": "Primera impresión",
        "Early read": "Primera impresión",
        "Split Decision": "Opiniones divididas",
        "Split": "Dividido",
        "Hidden gem": "Joya escondida",
        "Trending": "En tendencia",
        "Local Favorite": "Favorito local",
        "Favorite": "Favorito",
        "Recent": "Reciente",
        "No one has vibed this place yet.": "Nadie ha dejado una vibe aquí todavía.",
        "This place is just getting started.": "Este lugar apenas empieza a recibir vibes.",
        "The top vibes are close.": "Las vibes principales están muy parejas.",
        "Hidden gem.": "Una joya escondida.",
        "People are vibing this recently.": "La gente está dejando vibes aquí recientemente.",
        "A strong local favorite.": "Un claro favorito local.",
        "Recently submitted.": "Enviado recientemente.",

        // Place and rating cards.
        "SHARE IT.": "COMPÁRTELO.",
        "Share": "Compartir",
        "Share this vibe": "Compartir esta vibe",
        "Pick one to three vibes": "Elige de una a tres vibes",
        "Update vibes": "Actualizar vibes",
        "Submit vibes": "Enviar vibes",
        "Submitting": "Enviando",
        "Deleting": "Eliminando",
        "Delete my vibes": "Eliminar mis vibes",
        "Delete your vibes?": "¿Eliminar tus vibes?",
        "This removes your vibe submission from this place.": "Esto elimina tu envío de vibes de este lugar.",
        "Delete": "Eliminar",
        "Close place card": "Cerrar ficha del lugar",
        "No one else yet": "Nadie más todavía",
        "You picked": "Elegiste",
        "Everyone else": "Los demás",
        "Community": "Comunidad",
        "You helped shape the first read.": "Ayudaste a formar la primera impresión.",
        "This place is starting to get a vibe.": "Este lugar está empezando a tener una vibe.",
        "You're with the crowd.": "Coincides con la mayoría.",
        "You went against the crowd.": "Tu opinión va contra la mayoría.",
        "Top vibes here": "Vibes principales",
        "More": "Más",
        "Less": "Menos",
        "Show fewer top vibes": "Mostrar menos vibes principales",
        "Show all top vibes": "Mostrar todas las vibes principales",
        "Learn More": "Más información",
        "Apple Maps": "Mapas de Apple",
        "Google Maps": "Google Maps",
        "Contact, directions, pictures, etc.": "Contacto, indicaciones, fotos y más.",
        "AGREE OR DISAGREE?": "¿ESTÁS DE ACUERDO?",
        "SEE IT.\nVIBE IT.\nSHARE IT.": "MÍRALO.\nVÍBEALO.\nCOMPÁRTELO.",
        "GET THE APP!": "¡DESCARGA LA APP!",
        "Scan or tap the link to open VIBES Y'ALL.": "Escanea o toca el enlace para abrir VIBES Y'ALL.",
        "MY PICK": "MI ELECCIÓN",
        "VIBE IT": "DA TU VIBE",
        "VIBE SUBMITTED": "VIBE ENVIADA",
        "VIBES SUBMITTED": "VIBES ENVIADAS",

        // Common counts and messages.
        "Be the first": "Sé el primero",
        "%d vibe": "%d vibe",
        "%d vibes": "%d vibes",
        "%d vibe submitted": "%d vibe enviada",
        "%d vibes submitted": "%d vibes enviadas",
        "%@ vibe": "%@ vibe",
        "%@ vibes": "%@ vibes",
        "%@ vibe submitted": "%@ vibe enviada",
        "%@ vibes submitted": "%@ vibes enviadas",
        "%d nearby place": "%d lugar cercano",
        "%d nearby places": "%d lugares cercanos",
        "%d places in this area. Zoom in to see the list.": "%d lugares en esta zona. Acerca el mapa para ver la lista.",
        "Show %d more": "Mostrar %d más",
        "%d vibed in this area": "%d con vibe en esta zona",
        "%d trending · %d nearby": "%d en tendencia · %d cerca",
        "No %@ vibes nearby yet.": "Aún no hay vibes de %@ cerca.",
        "No past vibes in this area yet.": "Aún no tienes vibes anteriores en esta zona.",
        "No vibes in this area yet.": "Aún no hay vibes en esta zona.",
        "Vibe": "Dar vibe",
        "Check the vibes on %@.": "Mira las vibes de %@.",
        "Open %@ in Maps": "Abrir %@ en Mapas",
        "Share %@": "Compartir %@",
        "%@, %d percent": "%@, %d por ciento",
        "%@, mostly %@": "%@, principalmente %@",

        // Alerts and status.
        "OK": "Aceptar",
        "Still saving": "Aún guardando",
        "Your vibe is saved on this device and will retry when the connection improves.": "Tu vibe está guardada en este dispositivo y se volverá a intentar cuando mejore la conexión.",
        "Logged out": "Sesión cerrada",
        "You can keep using VIBES Y'ALL anonymously on this device.": "Puedes seguir usando VIBES Y'ALL de forma anónima en este dispositivo.",
        "Logged out locally": "Sesión cerrada en este dispositivo",
        "The server session could not be reached, but this device is no longer using the account session.": "No se pudo contactar la sesión del servidor, pero este dispositivo ya no usa la sesión de la cuenta.",
        "Keep vibing": "Sigue dejando vibes",
        "Could not check account status": "No se pudo comprobar el estado de la cuenta",
        "Account deleted": "Cuenta eliminada",
        "Account confirmed": "Cuenta confirmada",
        "Your past and future vibes can now stay tied to your account.": "Tus vibes pasadas y futuras ahora pueden permanecer vinculadas a tu cuenta.",
        "No map places found here.": "No se encontraron lugares del mapa aquí.",
        "Could not load that place. Try searching its name.": "No se pudo cargar ese lugar. Intenta buscarlo por nombre.",
        "Unnamed spot": "Lugar sin nombre",
        "The backend URL is not valid.": "La dirección del servidor no es válida.",
        "The backend did not return a usable response.": "El servidor no devolvió una respuesta válida.",
        "Check your email to confirm your VIBES Y'ALL account.": "Revisa tu correo para confirmar tu cuenta de VIBES Y'ALL.",
        "If that email has a VIBES Y'ALL account, a sign-in link is on the way.": "Si ese correo tiene una cuenta de VIBES Y'ALL, recibirás un enlace para iniciar sesión.",
        "You are logged out on this device.": "Cerraste sesión en este dispositivo.",
        "If an account matched this email and device, it has been deleted.": "Si había una cuenta asociada a este correo y dispositivo, se eliminó.",
        "You have vibed %d places.": "Has dejado vibes en %d lugares.",
        "%d more places unlock account backup.": "%d lugares más desbloquean el respaldo de la cuenta.",
        "Account backup unlocks after %d vibed places. You have %d, so %d more to go.": "El respaldo de la cuenta se desbloquea después de dejar vibes en %d lugares. Llevas %d; te faltan %d.",

        // Place categories.
        "Restaurant": "Restaurante",
        "Brewery": "Cervecería",
        "Bar": "Bar",
        "Park": "Parque",
        "Entertainment": "Entretenimiento",
        "Music Venue": "Sala de música",
        "Movie Theater": "Cine",
        "Theater": "Teatro",
        "Stadium": "Estadio",
        "Museum": "Museo",
        "Hotel": "Hotel",
        "School": "Escuela",
        "Health": "Salud",
        "Fitness": "Gimnasio",
        "Shop": "Tienda",
        "Gas": "Gasolina",
        "Gas Station": "Gasolinera",
        "Transit": "Transporte",
        "Parking": "Estacionamiento",
        "Bank": "Banco",
        "Library": "Biblioteca",
        "Public Service": "Servicio público",
        "ATM": "Cajero automático",
        "EV Charger": "Cargador eléctrico",
        "RV Park": "Parque de casas rodantes",
        "Amusement Park": "Parque de diversiones",
        "National Park": "Parque nacional",
        "Convention Center": "Centro de convenciones",
        "Performing Arts": "Artes escénicas",
        "Music venue": "Sala de música",
        "Nightlife": "Vida nocturna"
    ]
}
