CREATE TABLE users (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email text,
    username text UNIQUE NOT NULL,
    avatar_url text,
    total_score integer DEFAULT 0,
    games_played integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE games (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    letter text NOT NULL,
    round_time integer NOT NULL DEFAULT 60,
    status text NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'active', 'completed', 'cancelled')),
    creator_id uuid REFERENCES users(id) ON DELETE SET NULL,
    max_players integer DEFAULT 6,
    current_round integer DEFAULT 1,
    total_rounds integer DEFAULT 3,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE game_players (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id uuid NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score integer DEFAULT 0,
    answers jsonb DEFAULT '{}'::jsonb,
    is_ready boolean DEFAULT false,
    joined_at timestamptz DEFAULT now(),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(game_id, user_id)
);

CREATE TABLE chat_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id uuid REFERENCES games(id) ON DELETE CASCADE,
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    message text NOT NULL,
    message_type text DEFAULT 'text' CHECK (message_type IN ('text', 'system')),
    created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_games_creator_id ON games(creator_id);
CREATE INDEX idx_games_status ON games(status);
CREATE INDEX idx_games_created_at ON games(created_at);
CREATE INDEX idx_game_players_game_id ON game_players(game_id);
CREATE INDEX idx_game_players_user_id ON game_players(user_id);
CREATE INDEX idx_game_players_score ON game_players(score);
CREATE INDEX idx_chat_messages_game_id ON chat_messages(game_id);
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all users"
    ON users FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can view all games"
    ON games FOR SELECT
    USING (true);

CREATE POLICY "Users can create games"
    ON games FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Game creators can update their games"
    ON games FOR UPDATE
    USING (auth.uid() = creator_id);

CREATE POLICY "Users can view game players"
    ON game_players FOR SELECT
    USING (true);

CREATE POLICY "Users can join games"
    ON game_players FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own game player data"
    ON game_players FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view chat messages"
    ON chat_messages FOR SELECT
    USING (true);

CREATE POLICY "Users can send chat messages"
    ON chat_messages FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_games_updated_at BEFORE UPDATE ON games FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_game_players_updated_at BEFORE UPDATE ON game_players FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();