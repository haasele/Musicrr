// Musicrr Remote Control Web UI
class MusicrrRemote {
    constructor() {
        this.baseUrl = window.location.origin;
        this.accessToken = localStorage.getItem('musicrr_access_token');
        this.ws = null;
        this.currentState = {
            state: 'stopped',
            currentTrack: null,
            position: 0,
            duration: 0,
            volume: 1.0,
            queue: [],
            currentIndex: -1
        };
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        
        this.init();
    }

    init() {
        if (this.accessToken) {
            this.showMainScreen();
            this.connectWebSocket();
            this.loadInitialState();
        } else {
            this.showPairingScreen();
        }

        this.setupEventListeners();
    }

    setupEventListeners() {
        // Pairing
        document.getElementById('pair-button').addEventListener('click', () => {
            this.handlePairing();
        });
        document.getElementById('pairing-token').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.handlePairing();
            }
        });

        // Controls
        document.getElementById('play-pause-button').addEventListener('click', () => {
            this.togglePlayback();
        });
        document.getElementById('prev-button').addEventListener('click', () => {
            this.sendCommand('previous');
        });
        document.getElementById('next-button').addEventListener('click', () => {
            this.sendCommand('next');
        });

        // Progress bar
        document.getElementById('progress-bar').addEventListener('click', (e) => {
            const rect = e.currentTarget.getBoundingClientRect();
            const percent = (e.clientX - rect.left) / rect.width;
            const position = Math.floor(percent * this.currentState.duration);
            this.seek(position);
        });

        // Library toggle
        document.getElementById('library-toggle').addEventListener('click', () => {
            const content = document.getElementById('library-content');
            const toggle = document.getElementById('library-toggle');
            content.classList.toggle('hidden');
            toggle.textContent = content.classList.contains('hidden') ? '▼' : '▲';
        });

        // Library tabs
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const tab = btn.dataset.tab;
                this.switchLibraryTab(tab);
            });
        });
    }

    async handlePairing() {
        const token = document.getElementById('pairing-token').value.trim();
        const errorEl = document.getElementById('pairing-error');
        
        if (!token) {
            errorEl.textContent = 'Please enter a pairing token';
            errorEl.classList.remove('hidden');
            return;
        }

        try {
            const response = await fetch(`${this.baseUrl}/api/pair`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ pairingToken: token })
            });

            const data = await response.json();

            if (response.ok && data.success) {
                this.accessToken = data.accessToken;
                localStorage.setItem('musicrr_access_token', this.accessToken);
                this.showMainScreen();
                this.connectWebSocket();
                this.loadInitialState();
            } else {
                errorEl.textContent = data.error || 'Invalid pairing token';
                errorEl.classList.remove('hidden');
            }
        } catch (error) {
            errorEl.textContent = 'Connection error. Please check the server URL.';
            errorEl.classList.remove('hidden');
            console.error('Pairing error:', error);
        }
    }

    showPairingScreen() {
        document.getElementById('pairing-screen').classList.remove('hidden');
        document.getElementById('main-screen').classList.add('hidden');
    }

    showMainScreen() {
        document.getElementById('pairing-screen').classList.add('hidden');
        document.getElementById('main-screen').classList.remove('hidden');
    }

    connectWebSocket() {
        const wsUrl = `ws://${window.location.host}/ws?token=${this.accessToken}`;
        
        try {
            this.ws = new WebSocket(wsUrl);

            this.ws.onopen = () => {
                console.log('WebSocket connected');
                this.updateConnectionStatus(true);
                this.reconnectAttempts = 0;
            };

            this.ws.onmessage = (event) => {
                this.handleWebSocketMessage(JSON.parse(event.data));
            };

            this.ws.onerror = (error) => {
                console.error('WebSocket error:', error);
                this.updateConnectionStatus(false);
            };

            this.ws.onclose = () => {
                console.log('WebSocket disconnected');
                this.updateConnectionStatus(false);
                this.attemptReconnect();
            };
        } catch (error) {
            console.error('WebSocket connection error:', error);
            this.updateConnectionStatus(false);
        }
    }

    attemptReconnect() {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            console.log(`Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);
            setTimeout(() => {
                this.connectWebSocket();
            }, 2000 * this.reconnectAttempts);
        }
    }

    handleWebSocketMessage(message) {
        switch (message.event) {
            case 'initial.state':
                this.updateState(message.data.status);
                this.updateQueue(message.data.queue || []);
                break;
            case 'playback.state':
                this.currentState.state = message.data.state;
                this.updatePlayPauseButton();
                break;
            case 'playback.position':
                this.currentState.position = message.data.position;
                this.currentState.duration = message.data.duration;
                this.updateProgress();
                break;
            case 'playback.track':
                this.currentState.currentTrack = message.data.track;
                this.currentState.position = message.data.position;
                this.updateNowPlaying();
                break;
            case 'queue.updated':
                this.updateQueue(message.data.tracks || []);
                this.currentState.currentIndex = message.data.currentIndex;
                break;
            case 'volume.changed':
                this.currentState.volume = message.data.volume;
                break;
        }
    }

    async loadInitialState() {
        try {
            const response = await fetch(`${this.baseUrl}/api/status`, {
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`
                }
            });

            if (response.ok) {
                const data = await response.json();
                this.updateState(data);
            }
        } catch (error) {
            console.error('Error loading initial state:', error);
        }

        // Load queue
        try {
            const response = await fetch(`${this.baseUrl}/api/queue`, {
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`
                }
            });

            if (response.ok) {
                const data = await response.json();
                this.updateQueue(data.tracks || []);
                this.currentState.currentIndex = data.currentIndex || 0;
            }
        } catch (error) {
            console.error('Error loading queue:', error);
        }
    }

    updateState(status) {
        this.currentState.state = status.state || 'stopped';
        this.currentState.currentTrack = status.currentTrack;
        this.currentState.position = status.position || 0;
        this.currentState.duration = status.duration || 0;
        this.currentState.volume = status.volume || 1.0;

        this.updateNowPlaying();
        this.updatePlayPauseButton();
        this.updateProgress();
    }

    updateNowPlaying() {
        const track = this.currentState.currentTrack;
        
        if (track) {
            document.getElementById('track-title').textContent = track.title || 'Unknown';
            document.getElementById('track-artist').textContent = track.artist || 'Unknown Artist';
            document.getElementById('track-album').textContent = track.album || '';

            if (track.coverArt) {
                const img = document.getElementById('cover-art');
                img.src = track.coverArt;
                img.classList.remove('hidden');
                document.getElementById('cover-art-placeholder').classList.add('hidden');
            } else {
                document.getElementById('cover-art').classList.add('hidden');
                document.getElementById('cover-art-placeholder').classList.remove('hidden');
            }
        } else {
            document.getElementById('track-title').textContent = 'No track playing';
            document.getElementById('track-artist').textContent = '—';
            document.getElementById('track-album').textContent = '—';
            document.getElementById('cover-art').classList.add('hidden');
            document.getElementById('cover-art-placeholder').classList.remove('hidden');
        }
    }

    updatePlayPauseButton() {
        const btn = document.getElementById('play-pause-button');
        btn.textContent = this.currentState.state === 'playing' ? '⏸' : '▶';
    }

    updateProgress() {
        const percent = this.currentState.duration > 0 
            ? (this.currentState.position / this.currentState.duration) * 100 
            : 0;
        document.getElementById('progress-fill').style.width = `${percent}%`;
        
        document.getElementById('current-time').textContent = this.formatTime(this.currentState.position);
        document.getElementById('total-time').textContent = this.formatTime(this.currentState.duration);
    }

    updateQueue(queue) {
        this.currentState.queue = queue;
        const queueList = document.getElementById('queue-list');
        const queueCount = document.getElementById('queue-count');
        
        queueCount.textContent = `(${queue.length})`;

        if (queue.length === 0) {
            queueList.innerHTML = '<p class="secondary">Queue is empty</p>';
            return;
        }

        queueList.innerHTML = queue.map((track, index) => {
            const isActive = index === this.currentState.currentIndex;
            return `
                <div class="queue-item ${isActive ? 'active' : ''}" data-index="${index}">
                    <div class="queue-item-info">
                        <div class="queue-item-title">${this.escapeHtml(track.title || 'Unknown')}</div>
                        <div class="queue-item-artist">${this.escapeHtml(track.artist || 'Unknown Artist')}</div>
                    </div>
                </div>
            `;
        }).join('');

        // Add click handlers
        queueList.querySelectorAll('.queue-item').forEach(item => {
            item.addEventListener('click', () => {
                const index = parseInt(item.dataset.index);
                // TODO: Implement play from queue position
            });
        });
    }

    updateConnectionStatus(connected) {
        const statusDot = document.querySelector('.status-dot');
        const statusText = document.getElementById('status-text');
        
        if (connected) {
            statusDot.classList.add('connected');
            statusText.textContent = 'Connected';
        } else {
            statusDot.classList.remove('connected');
            statusText.textContent = 'Disconnected';
        }
    }

    async togglePlayback() {
        if (this.currentState.state === 'playing') {
            await this.sendApiRequest('POST', '/api/pause');
        } else {
            await this.sendApiRequest('POST', '/api/resume');
        }
    }

    async seek(position) {
        await this.sendApiRequest('POST', '/api/seek', { position });
    }

    sendCommand(command, params = {}) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify({
                command: command,
                params: params
            }));
        } else {
            // Fallback to REST API
            this.sendApiRequest('POST', `/api/${command}`, params);
        }
    }

    async sendApiRequest(method, endpoint, body = null) {
        try {
            const options = {
                method: method,
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`,
                    'Content-Type': 'application/json'
                }
            };

            if (body) {
                options.body = JSON.stringify(body);
            }

            const response = await fetch(`${this.baseUrl}${endpoint}`, options);
            
            if (response.status === 401) {
                // Token expired, clear and show pairing screen
                localStorage.removeItem('musicrr_access_token');
                this.accessToken = null;
                this.showPairingScreen();
                return null;
            }

            return await response.json();
        } catch (error) {
            console.error(`API request error (${endpoint}):`, error);
            return null;
        }
    }

    switchLibraryTab(tab) {
        // Update tab buttons
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === tab);
        });

        // Update tab content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.toggle('active', content.id === `${tab}-tab`);
        });

        // Load library data
        this.loadLibraryTab(tab);
    }

    async loadLibraryTab(tab) {
        // TODO: Implement library loading
        const content = document.getElementById(`${tab}-tab`);
        content.innerHTML = '<p class="secondary">Library browsing coming soon...</p>';
    }

    formatTime(ms) {
        const seconds = Math.floor(ms / 1000);
        const minutes = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${minutes}:${secs.toString().padStart(2, '0')}`;
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.musicrr = new MusicrrRemote();
});
