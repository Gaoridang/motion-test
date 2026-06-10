import { PhotoThumbnailGroup } from './components/PhotoThumbnailGroup'

export default function App() {
  return (
    <main className="app">
      <h1>Photo Thumbnail Group</h1>
      <p className="hint">Tap a thumbnail to spread. Tap another to switch.</p>
      <PhotoThumbnailGroup />
    </main>
  )
}
