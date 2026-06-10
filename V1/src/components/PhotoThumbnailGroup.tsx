import { useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'

const THUMB_SIZE = 72
const STACK_GAP = 10

const PHOTOS = [
  { id: 'a', label: 'A', gradient: 'linear-gradient(135deg, #f97316, #ea580c)' },
  { id: 'b', label: 'B', gradient: 'linear-gradient(135deg, #3b82f6, #1d4ed8)' },
  { id: 'c', label: 'C', gradient: 'linear-gradient(135deg, #22c55e, #15803d)' },
  { id: 'd', label: 'D', gradient: 'linear-gradient(135deg, #a855f7, #7e22ce)' },
] as const

function getStackOrder(activeIndex: number): number[] {
  const after = PHOTOS.map((_, i) => i).filter((i) => i > activeIndex).reverse()
  const before = PHOTOS.map((_, i) => i).filter((i) => i < activeIndex).reverse()
  return [...after, ...before, activeIndex]
}

function Thumbnail({
  photo,
  dimmed = false,
}: {
  photo: (typeof PHOTOS)[number]
  dimmed?: boolean
}) {
  return (
    <div
      className="thumbnail"
      style={{
        background: photo.gradient,
        opacity: dimmed ? 0.45 : 1,
      }}
    >
      {photo.label}
    </div>
  )
}

export function PhotoThumbnailGroup() {
  const [activeIndex, setActiveIndex] = useState<number | null>(null)

  const handleTouch = (index: number) => {
    setActiveIndex((current) => (current === index ? null : index))
  }

  const stackOrder = activeIndex !== null ? getStackOrder(activeIndex) : []
  const stackHeight =
    activeIndex !== null
      ? THUMB_SIZE + (stackOrder.length - 1) * (THUMB_SIZE + STACK_GAP)
      : 0

  return (
    <div className="photo-group">
      <div className="stack-zone" style={{ height: stackHeight }}>
        <AnimatePresence>
          {activeIndex !== null && (
            <motion.div
              key={activeIndex}
              className="stack"
              style={{ left: activeIndex * (THUMB_SIZE + 12) }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
            >
              {stackOrder.map((photoIndex, stackPos) => {
                const photo = PHOTOS[photoIndex]
                const isActive = photoIndex === activeIndex
                // Stack grows upward: active thumb stays at bottom (y=0), others go negative y
                const y = -(stackOrder.length - 1 - stackPos) * (THUMB_SIZE + STACK_GAP)

                return (
                  <motion.div
                    key={photo.id}
                    className="stack-item"
                    style={{ zIndex: stackPos + 1 }}
                    initial={{ y: 0, scale: 0.88, opacity: 0 }}
                    animate={{
                      y,
                      scale: isActive ? 1.05 : 1,
                      opacity: 1,
                    }}
                    exit={{
                      y: 0,
                      scale: 0.88,
                      opacity: 0,
                      transition: { duration: 0.18 },
                    }}
                    transition={{
                      type: 'spring',
                      stiffness: 420,
                      damping: 32,
                      delay: stackPos * 0.04,
                    }}
                  >
                    <Thumbnail photo={photo} />
                  </motion.div>
                )
              })}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <div className="divider" />

      <div className="horizontal-row">
        {PHOTOS.map((photo, index) => {
          const isActive = activeIndex === index

          return (
            <motion.button
              key={photo.id}
              type="button"
              className="thumb-button"
              onClick={() => handleTouch(index)}
              whileTap={{ scale: 0.94 }}
              aria-pressed={isActive}
              aria-label={`Spread photo ${photo.label}`}
            >
              <Thumbnail photo={photo} dimmed={isActive} />
            </motion.button>
          )
        })}
      </div>
    </div>
  )
}
