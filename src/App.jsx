import { OrthographicCamera, OrbitControls, shaderMaterial, useVideoTexture } from '@react-three/drei'
import { Canvas, extend, useThree, useFrame, useLoader } from '@react-three/fiber'
import { useRef, useEffect, useState } from 'react'
import * as THREE from 'three'

import vertex from './shaders/drawing/vertex.glsl'
import fragment from './shaders/drawing/fragment.glsl'

const ShaderObjectMaterial = new shaderMaterial(
  {
    uTime: 0.0,
    uResolution: new THREE.Vector2( window.innerWidth, window.innerHeight ),
    uDiffuse1: null,
    uDiffuse2: null, 
    uVignette: null
  },
  vertex,
  fragment
)
extend({ ShaderObjectMaterial })

// Reload page once user is finished resizing the window
const debounce = (func) => {
  var timer
  return (event) => {
    if (timer) clearTimeout(timer)
    timer = setTimeout(func, 100, event)
  }
}
window.addEventListener('resize', debounce(function(e) { location.reload() }))

const ShaderObject = ({ cameraStream, isCamera, isTexture }) => {
  const shaderObject = useRef()
  // Enable next line if this is a texture based shader
  const diffuseTexture1 = useLoader(THREE.TextureLoader, '/textures/test5.jpg')
  diffuseTexture1.minFilter = THREE.NearestFilter
  diffuseTexture1.magFilter = THREE.NearestFilter
  const diffuseTexture2 = useLoader(THREE.TextureLoader, '/textures/tomato.jpg')
  diffuseTexture2.minFilter = THREE.NearestFilter
  diffuseTexture2.magFilter = THREE.NearestFilter
  const vignette = useLoader(THREE.TextureLoader, '/textures/vignette.jpg')
  vignette.minFilter = THREE.NearestFilter
  vignette.magFilter = THREE.NearestFilter

  // Enable next line if this is a camera based shader
  // const cameraTexture = useVideoTexture(cameraStream)
  
  // Reload page is either the fragment or vertex shader files change
  useEffect(() => {
    if (shaderObject.current.material.fragmentShader !== fragment || shaderObject.current.material.vertexShader !== vertex)
      location.reload()
  })

  useEffect(() => {
    if (isCamera) {
      shaderObject.current.material.uDiffuse = cameraTexture
    }
    if (isTexture) {
      shaderObject.current.material.uDiffuse1 = diffuseTexture1
      shaderObject.current.material.uDiffuse2 = diffuseTexture2
      shaderObject.current.material.uVignette = vignette
    }
  }, [])

  useFrame((state) => {
    shaderObject.current.material.uTime = state.clock.elapsedTime
  })

  return <mesh position={[ 0.5, 0.5, 0.0 ]}  scale={ 1.0 } ref={ shaderObject }>
    <planeGeometry args={[ 1.0, 1.0, ]} />
    <shaderObjectMaterial />
  </mesh>
}

const Scene = ({ isCamera, isTexture }) => {
  useThree((state) => {
    state.camera.position.set(0, 0, 1)
  })

  return (<>
    <ShaderObject isCamera={ isCamera } isTexture={ isTexture }/>
  </>)
}

const CameraScene = ({ cameraStream, isCamera }) => {
  useThree((state) => {
    state.camera.position.set(0, 0, 1)
  })

  return (<>
    <ShaderObject cameraStream={ cameraStream } isCamera={ isCamera } />
  </>)
}

export default function App() {
  const [ cameraPermissionsGranted, setCameraPermissionsGranted ] = useState(false)
  const [ cameraStream, setCameraStream ] = useState()
  const isCamera = false

  const activeCamera = async () => {
    setCameraStream(await navigator.mediaDevices.getUserMedia({ video: true }))
    setCameraPermissionsGranted(true)
  }
  useEffect(() => {
  }, [])
  return (
    <>
      <Canvas>
        {/* <OrbitControls /> */}
        <OrthographicCamera
          makeDefault
          top={ 1 }
          left={ 0 }
          right={ 1 }
          bottom={ 0 }
          near={ 0.1 }
          far={ 1000 }
        />
        <Scene isCamera={ false } isTexture={ true } />
        {/* {
          cameraStream &&
            <CameraScene 
              isCamera={ true }
              cameraStream={ cameraStream }
            />
        } */}
      </Canvas>
      { isCamera && 
        <div style={{ 
          width: '100%', 
          position: 'absolute', 
          zIndex: 999, 
          bottom: 0, 
          left: 0, 
          right: 0, 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center', 
          margin: '0 auto', 
          padding: '0.5rem',
        }}>
          <button onClick={ activeCamera }>
            Grant Camera Permissions
          </button>
        </div>
      }
    </>
  )
}