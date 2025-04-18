#pragma once

#include "debug.hpp"
#include <cuda_runtime.h>
#include <version>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstdarg>
#include <memory>
#include <new>
#include <string>
#include <system_error>
#include <utility>
#include <vector>
#if __cpp_lib_source_location
#include <source_location>
#endif
// #if __cpp_lib_memory_resource
// #include <memory_resource>
// #endif

namespace cudapp {

inline std::error_category const &cudaErrorCategory() noexcept {
    static struct : std::error_category {
        char const *name() const noexcept override {
            return "cuda";
        }

        std::string message(int ev) const override {
            return cudaGetErrorString(static_cast<cudaError_t>(ev));
        }
    } category;

    return category;
}

inline std::error_code makeCudaErrorCode(cudaError_t e) noexcept {
    return std::error_code(static_cast<int>(e), cudaErrorCategory());
}

inline void throwCudaError(cudaError_t err, char const *file, int line) {
    throw std::system_error(makeCudaErrorCode(err),
                            std::string(file ? file : "??") + ":" + std::to_string(line));
}

struct CheckCuda {
    const char *file = nullptr;
    int line = 0;

#if __cpp_lib_source_location
    constexpr CheckCuda(std::source_location const &loc = std::source_location::current())
        : file(loc.file_name()), line(loc.line())
    {}
#else
#if defined(__GNUC__) && defined(__has_builtin)
#if __has_builtin(__builtin_FILE) && __has_builtin(__builtin_LINE)
    constexpr CheckCuda(const char *file = __builtin_FILE(), int line = __builtin_LINE())
        : file(file), line(line)
    {}
#endif
#endif
#endif

    void operator=(cudaError_t err) {
        if (err != cudaSuccess) [[unlikely]] {
            ::cudapp::throwCudaError(err, file, line);
        }
    }
};

#define CHECK_CUDA(expr) \
    do { \
        cudaError_t err = (expr); \
        if (err != cudaSuccess) [[unlikely]] { \
            ::cudapp::throwCudaError(err, __FILE__, __LINE__); \
        } \
    } while (0)

struct CudaHostArena {
    static cudaError_t doMalloc(void **ptr, size_t size) noexcept {
        return cudaMallocHost(ptr, size);
    }

    static cudaError_t doFree(void *ptr) noexcept {
        return cudaFreeHost(ptr);
    }
};

struct CudaDeviceArena {
    static cudaError_t doMalloc(void **ptr, size_t size) noexcept {
        return cudaMalloc(ptr, size);
    }

    static cudaError_t doFree(void *ptr) noexcept {
        return cudaFree(ptr);
    }
};

struct CudaManagedArena {
    static cudaError_t doMalloc(void **ptr, size_t size) noexcept {
        return cudaMallocManaged(ptr, size);
    }

    static cudaError_t doFree(void *ptr) noexcept {
        return cudaFree(ptr);
    }
};

struct CudaAsyncDeviceArena {
private:
    cudaStream_t m_stream;

public:
    cudaError_t doMalloc(void **ptr, size_t size) const noexcept {
        return cudaMallocAsync(&ptr, size, m_stream);
    }

    cudaError_t doFree(void *ptr) const noexcept {
        return cudaFreeAsync(ptr, m_stream);
    }

    CudaAsyncDeviceArena(cudaStream_t stream = nullptr) noexcept
        : m_stream(stream) {}
};

struct CudaAsyncPoolDeviceArena {
private:
    cudaMemPool_t m_pool;
    cudaStream_t m_stream;

public:
    cudaError_t doMalloc(void **ptr, size_t size) const noexcept {
        return cudaMallocFromPoolAsync(&ptr, size, m_pool, m_stream);
    }

    cudaError_t doFree(void *ptr) const noexcept {
        return cudaFreeAsync(ptr, m_stream);
    }

    CudaAsyncPoolDeviceArena(cudaMemPool_t pool,
                             cudaStream_t stream = nullptr) noexcept
        : m_pool(pool),
          m_stream(stream) {}
};

template <class Ptr>
struct GenericResourcePtr {
    Ptr m_ptr;

    GenericResourcePtr(std::nullptr_t = nullptr) noexcept : m_ptr() {}

    explicit GenericResourcePtr(Ptr ptr) noexcept : m_ptr(ptr) {}

    GenericResourcePtr(GenericResourcePtr const &) = delete;

    GenericResourcePtr &operator=(GenericResourcePtr const &) = delete;

    GenericResourcePtr(GenericResourcePtr &&other) noexcept
        : m_ptr(other.m_ptr) {
        other.m_ptr = nullptr;
    }

    GenericResourcePtr &operator=(GenericResourcePtr &&other) noexcept {
        std::swap(m_ptr, other.m_ptr);
        return *this;
    }

    Ptr get() const noexcept {
        return m_ptr;
    }

    operator Ptr() const noexcept {
        return m_ptr;
    }

    explicit operator bool() const noexcept {
        return m_ptr != nullptr;
    }
};

struct CudaMemPool : GenericResourcePtr<cudaMemPool_t> {
private:
    CudaMemPool(cudaMemPool_t ptr) noexcept
        : GenericResourcePtr<cudaMemPool_t>(ptr) {}

public:
    CudaMemPool(std::nullptr_t) noexcept {}

    struct Builder {
    private:
        cudaMemPoolProps props{};

    public:
        Builder() noexcept {
            props.allocType = cudaMemAllocationTypePinned;
        }

        Builder &withLocation(cudaMemLocationType type,
                              int node_id = 0) noexcept {
            props.location.type = type;
            props.location.id = node_id;
            return *this;
        }

        Builder &withMaxSize(size_t size) noexcept {
            props.maxSize = size;
            return *this;
        }

        Builder &
        withHandleTypes(cudaMemAllocationHandleType handleTypes) noexcept {
            props.handleTypes = handleTypes;
            return *this;
        }

        CudaMemPool build() {
            cudaMemPool_t pool;
            CHECK_CUDA(cudaMemPoolCreate(&pool, &props));
            return CudaMemPool(pool);
        }
    };

    static CudaMemPool getDeviceMemPool(int device = 0) {
        cudaMemPool_t pool;
        CHECK_CUDA(cudaDeviceGetMemPool(&pool, device));
        return CudaMemPool(pool);
    }

    template <class T>
    void setAttribute(cudaMemPoolAttr attr,
                      std::decay_t<T> const &value) const {
        CHECK_CUDA(cudaMemPoolSetAttribute(*this, attr, &value));
    }

    template <class T>
    void getAttribute(cudaMemPoolAttr attr) const {
        T value;
        CHECK_CUDA(cudaMemPoolGetAttribute(*this, attr, &value));
        return value;
    }

    void trimTo(size_t minBytesToKeep) const {
        CHECK_CUDA(cudaMemPoolTrimTo(*this, minBytesToKeep));
    }

    ~CudaMemPool() {
        if (*this) {
            CHECK_CUDA(cudaMemPoolDestroy(*this));
        }
    }
};

struct CudaEvent : GenericResourcePtr<cudaEvent_t> {
private:
    explicit CudaEvent(cudaEvent_t ptr) noexcept
        : GenericResourcePtr<cudaEvent_t>(ptr) {}

public:
    CudaEvent(std::nullptr_t) noexcept {}

    struct Builder {
    private:
        int flags = cudaEventDefault;

    public:
        Builder &withBlockingSync(bool blockingSync = true) noexcept {
            if (blockingSync) {
                flags |= cudaEventBlockingSync;
            } else {
                flags &= ~cudaEventBlockingSync;
            }
            return *this;
        }

        Builder &withDisableTiming(bool disableTiming = true) noexcept {
            if (disableTiming) {
                flags |= cudaEventDisableTiming;
            } else {
                flags &= ~cudaEventDisableTiming;
            }
            return *this;
        }

        Builder &withInterprocess(bool interprocess = true) noexcept {
            if (interprocess) {
                flags |= cudaEventInterprocess;
            } else {
                flags &= ~cudaEventInterprocess;
            }
            return *this;
        }

        CudaEvent build() {
            cudaEvent_t event;
            CHECK_CUDA(cudaEventCreateWithFlags(&event, flags));
            return CudaEvent(event);
        }
    };

    void join() const {
        CHECK_CUDA(cudaEventSynchronize(*this));
    }

    bool joinReady() const {
        cudaError_t res = cudaEventQuery(*this);
        if (res == cudaSuccess) {
            return true;
        }
        if (res == cudaErrorNotReady) {
            return false;
        }
        CHECK_CUDA(res);
        return false;
    }

    float elapsedMillis(CudaEvent const &event) const {
        float result;
        CHECK_CUDA(cudaEventElapsedTime(&result, *this, event));
        return result;
    }

    ~CudaEvent() {
        if (*this) {
            CHECK_CUDA(cudaEventDestroy(*this));
        }
    }
};

struct CudaStream : GenericResourcePtr<cudaStream_t> {
private:
    explicit CudaStream(cudaStream_t ptr) noexcept
        : GenericResourcePtr<cudaStream_t>(ptr) {}

public:
    CudaStream(std::nullptr_t) noexcept {}

    struct Builder {
    private:
        int flags = cudaStreamDefault;

    public:
        Builder &withNonBlocking(bool nonBlocking = true) noexcept {
            if (nonBlocking) {
                flags |= cudaStreamNonBlocking;
            } else {
                flags &= ~cudaStreamNonBlocking;
            }
            return *this;
        }

        CudaStream build() {
            cudaStream_t stream;
            CHECK_CUDA(cudaStreamCreateWithFlags(&stream, flags));
            return CudaStream(stream);
        }
    };

    static CudaStream nullStream() noexcept {
        return CudaStream(nullptr);
    }

    void copy(void *dst, void *src, size_t size, cudaMemcpyKind kind) const {
        CHECK_CUDA(cudaMemcpyAsync(dst, src, size, kind, *this));
    }

    void copyD2D(void *dst, void *src, size_t size) const {
        copy(dst, src, size, cudaMemcpyDeviceToDevice);
    }

    void copyH2D(void *dst, void *src, size_t size) const {
        copy(dst, src, size, cudaMemcpyHostToDevice);
    }

    void copyD2H(void *dst, void *src, size_t size) const {
        copy(dst, src, size, cudaMemcpyDeviceToHost);
    }

    void copyH2H(void *dst, void *src, size_t size) const {
        copy(dst, src, size, cudaMemcpyHostToHost);
    }

    void record(CudaEvent const &event) const {
        CHECK_CUDA(cudaEventRecord(event, *this));
    }

    void wait(CudaEvent const &event,
              unsigned int flags = cudaEventWaitDefault) const {
        CHECK_CUDA(cudaStreamWaitEvent(*this, event, flags));
    }

    void join() const {
        CHECK_CUDA(cudaStreamSynchronize(*this));
    }

    void joinAsync(cudaStreamCallback_t callback, void *userData) const {
        CHECK_CUDA(cudaStreamAddCallback(*this, callback, userData, 0));
    }

    template <class Func>
    void joinAsync(Func &&func) const {
        auto userData = std::make_unique<Func>();
        cudaStreamCallback_t callback = [](cudaStream_t stream,
                                           cudaError_t status, void *userData) {
            std::unique_ptr<Func> func(static_cast<Func *>(userData));
            (*func)(stream, status);
        };
        joinAsync(callback, userData.get());
        userData.release();
    }

    bool joinReady() const {
        cudaError_t res = cudaStreamQuery(*this);
        if (res == cudaSuccess) {
            return true;
        }
        if (res == cudaErrorNotReady) {
            return false;
        }
        CHECK_CUDA(res);
        return false;
    }

    void setAttribute(cudaStreamAttrID attr,
                      cudaStreamAttrValue const &value) const {
        CHECK_CUDA(cudaStreamSetAttribute(*this, attr, &value));
    }

    ~CudaStream() {
        if (*this) {
            CHECK_CUDA(cudaStreamDestroy(*this));
        }
    }
};

template <class T, class Arena = CudaManagedArena>
struct CudaAllocator : private Arena {
    using value_type = T;
    using pointer = T *;
    using reference = T &;
    using const_pointer = T const *;
    using const_reference = T const &;
    using size_type = size_t;
    using difference_type = ptrdiff_t;

    using propagate_on_container_move_assignment = std::true_type;
    using is_always_equal = std::true_type;

    static_assert(alignof(T) <= 256,
                  "CudaAllocator alignment max to 256-bytes");

    CudaAllocator() = default;

    CudaAllocator(Arena arena) noexcept : Arena(std::move(arena)) {}

    T *allocate(size_t size) {
        void *ptr = nullptr;
        if (sizeof(T) > 1 && size > std::numeric_limits<size_t>::max() /
                                         sizeof(T)) [[unlikely]] {
            throw std::bad_array_new_length();
        }
        cudaError_t res = Arena::doMalloc(&ptr, size * sizeof(T));
        if (res == cudaErrorMemoryAllocation) [[unlikely]] {
            throw std::bad_alloc();
        }
        CHECK_CUDA(res /* Arena::doMalloc */);
        return static_cast<T *>(ptr);
    }

    void deallocate(T *ptr, size_t size = 0) {
        CHECK_CUDA(Arena::doFree(ptr));
    }

#if __cpp_constexpr_dynamic_alloc && __cpp_if_constexpr
    template <class... Args>
    static std::enable_if_t<sizeof...(Args)>
    construct(T *p, Args &&...args) noexcept(noexcept(
        std::construct_at(p, std::forward<Args>(args)...))) {
        std::construct_at(p, std::forward<Args>(args)...);
    }

    static void
    construct(T *p) noexcept(noexcept(std::construct_at(p))) {
        if constexpr (!std::is_trivial_v<T>) {
            std::construct_at(p);
        }
    }

    static void destroy(T *p) noexcept(noexcept(std::destroy_at(p))) {
        std::destroy_at(p);
    }
#else
    template <class... Args>
    static std::enable_if_t<sizeof...(Args)>
    construct(T *p, Args &&...args) noexcept(noexcept(
        ::new (static_cast<void *>(p)) T(std::forward<Args>(args)...))) {
        ::new (static_cast<void *>(p)) T(std::forward<Args>(args)...);
    }

    static void
    construct(T *p) noexcept(noexcept(::new (static_cast<void *>(p)) T)) {
        ::new (static_cast<void *>(p)) T;
    }

    static void destroy(T *p) noexcept(noexcept(p->~T())) {
        p->~T();
    }
#endif

    template <class U>
    constexpr CudaAllocator(CudaAllocator<U> const &other) noexcept {}

    template <class U>
    constexpr bool operator==(CudaAllocator<U> const &other) const noexcept {
        return true;
    }

    template <class U>
    struct rebind {
        using other = CudaAllocator<U>;
    };
};

template <class T>
using CudaVector = std::vector<T, CudaAllocator<T>>;

#if defined(__clang__) && defined(__CUDACC__) && defined(__GLIBCXX__)
__host__ __device__ static void printf(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
#if __CUDA_ARCH__
    ::vprintf(fmt, (const char *)args);
#else
    ::vprintf(fmt, args);
#endif
    va_end(args);
}
#else
using ::printf;
#endif

template <class Vector>
struct CudaVectorResizer {
private:
    Vector &m_vec;
    size_t m_size;

public:
    explicit CudaVectorResizer(Vector &vec) noexcept
    : m_vec(vec), m_size(vec.size()) {}

    CudaVectorResizer &operator=(CudaVectorResizer &&) = delete;

    operator size_t &() noexcept {
        return m_size;
    }

    operator size_t *() noexcept {
        return &m_size;
    }

    ~CudaVectorResizer() noexcept(noexcept(m_vec.resize(m_size))) {
        m_vec.resize(m_size);
    }
};

#if __cpp_deduction_guides
template <class Vector>
CudaVectorResizer(Vector &vec) -> CudaVectorResizer<Vector>;
#endif

// #if __cpp_lib_memory_resource
// template <class Arena>
// struct CudaResource : std::pmr::memory_resource, private Arena {
//     void *do_allocate(size_t size, size_t alignment) override {
//         if (alignment > 256) [[unlikely]]
//             throw std::bad_alloc();
//         void *ptr = nullptr;
//         CHECK_CUDA(Arena::doMalloc(&ptr, size));
//         return ptr;
//     }
//
//     void do_deallocate(void *ptr, size_t size, size_t alignment) override {
//         CHECK_CUDA(Arena::doFree(ptr));
//     }
//
//     bool do_is_equal(std::pmr::memory_resource const &other) const noexcept
//     override {
//         return this == &other;
//     }
// };
// #endif

} // namespace cupp
