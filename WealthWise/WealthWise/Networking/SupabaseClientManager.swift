import Foundation
import Supabase

final class SupabaseClientManager {
    static let shared = SupabaseClientManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Configuration.supabaseURL)!,
            supabaseKey: Configuration.supabaseAnonKey
        )
    }
}
