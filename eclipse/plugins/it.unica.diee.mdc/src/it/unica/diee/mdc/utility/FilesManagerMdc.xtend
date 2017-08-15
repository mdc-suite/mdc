/*
 */
package it.unica.diee.mdc.utility;

import java.io.File
import org.eclipse.core.runtime.FileLocator
import org.osgi.framework.FrameworkUtil

import net.sf.orcc.util.FilesManager
import java.io.FileNotFoundException
import java.net.URI
import java.util.jar.JarFile
import org.eclipse.core.runtime.Assert
import java.io.FileInputStream
import java.util.jar.JarEntry
import java.util.Collections

import static net.sf.orcc.util.Result.*
import java.io.InputStream
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.FileOutputStream
import net.sf.orcc.util.Result

/**
 * Utility class to manipulate files. It brings everything needed to extract files
 * from a jar plugin to the filesystem, check if 2 files are identical, read/write
 * files, etc.
 */
class FilesManagerMdc extends FilesManager {

	private static val BUFFER_SIZE = 1024
	
	/**
	 * <p>Copy the file or the folder at given <em>path</em> to the given
	 * <em>target folder</em>.</p>
	 * 
	 * <p>It is important to understand that the resource (file or folder) at the given path
	 * will be copied <b>into</b> the target folder. For example,
	 * <code>extract("/path/to/file.txt", "/home/johndoe")</code> will copy <em>file.txt</em>
	 * into <em>/home/johndoe</em>, and <code>extract("/path/to/MyFolder", "/home/johndoe")</code>
	 * will create <em>MyFolder</em> directory in <em>/home/johndoe</em> and copy all files
	 * from the source folder into it.
	 * </p>
	 * 
	 * @param path The path of the source (folder or file) to copy
	 * @param targetFolder The directory where to copy the source element
	 * @return A Result object counting exactly how many files have been really
	 * 		written, and how many haven't because they were already up-to-date
	 * @throws FileNotFoundException If not resource have been found at the given path
	 */
	 def static extract(String path, String targetFolder) {
		val targetF = new File(targetFolder.sanitize)
		val url = path.url
		if(url == null) {
			throw new FileNotFoundException(path)
		}
		if (url.protocol.equals("jar")) {
			val splittedURL = url.file.split("!")
			val fileUri = new URI(splittedURL.head)
			val jar = new JarFile(new File(fileUri))
			jarExtract(jar, splittedURL.last, targetF)
		} else {
			fsExtract(new File(path.url.toURI), targetF)
		}
	}
	
	/**
	 * Copy the given <i>source</i> directory and its content into
	 * the given <em>targetFolder</em> directory.
	 * 
	 * @param source
	 * 			The source path of an existing file
	 * @param targetFolder
	 * 			Path to the folder where source will be copied
	 */
	private def static fsDirectoryExtract(File source, File targetFolder) {
		Assert.isTrue(source.directory)
		if (!targetFolder.exists)
			Assert.isTrue(targetFolder.mkdirs)
		else
			Assert.isTrue(targetFolder.directory)

		val result = newInstance
		for (file : source.listFiles) {
			result.merge(
				file.fsExtract(targetFolder)
			)
		}
		return result
	}
	
	/**
	 * Copy the given <i>source</i> file to the given <em>targetFile</em>
	 * path.
	 * 
	 * @param source
	 * 			An existing File instance
	 * @param targetFolder
	 * 			The target folder to copy the file
	 */
	private def static Result fsExtract(File source, File targetFolder) {
		if (!source.exists) {
			throw new FileNotFoundException(source.path)
		}
		val target = new File(targetFolder, source.name)
		if (source.file) {
			if (source.isContentEqual(target)) {
				newCachedInstance
			} else {
				new FileInputStream(source).streamExtract(target)
			}
		}
		else if (source.directory)
			source.fsDirectoryExtract(target)
	}
	
	/**
	 * Extract all files in the given <em>entry</em> from the given <em>jar</em> into
	 * the <em>target folder</em>.
	 */
	private def static jarDirectoryExtract(JarFile jar, JarEntry entry, File targetFolder) {
		val prefix = entry.name
		val entries = Collections::list(jar.entries).filter[name.startsWith(prefix)]
		val result = newInstance
		for (e : entries) {
			result.merge(
				jarFileExtract(jar, e, new File(targetFolder, e.name.substring(prefix.length)))
			)
		}
		return result
	}
	
	/**
	 * Starting point for extraction of a file/folder resource from a jar. 
	 */
	private def static jarExtract(JarFile jar, String path, File targetFolder) {
		val updatedPath = if (path.startsWith("/")) {
				path.substring(1)
			} else {
				path
			}

		val entry = jar.getJarEntry(updatedPath)
		// Remove the last char if it is '/'
		val name =
			if(entry.name.endsWith("/"))
				entry.name.substring(0, entry.name.length - 1)
			else
				entry.name
		val fileName =
			if(name.lastIndexOf("/") != -1)
				name.substring(name.lastIndexOf("/"))
			else
				name

		if (entry.directory) {
			jarDirectoryExtract(jar, entry, new File(targetFolder, fileName))
		} else {
			val entries = Collections::list(jar.entries).filter[name.startsWith(updatedPath)]
			if (entries.size > 1) {
				jarDirectoryExtract(jar, entry, new File(targetFolder, fileName))
			} else {
				jarFileExtract(jar, entry, new File(targetFolder, fileName))
			}
		}
	}
	
	/**
	 * Extract the file <em>entry</em> from the given <em>jar</em> into the <em>target
	 * file</em>.
	 */
	private def static jarFileExtract(JarFile jar, JarEntry entry, File targetFile) {
		targetFile.parentFile.mkdirs
		if (entry.directory) {
			targetFile.mkdir
			return newInstance
		}
		if (jar.getInputStream(entry).isContentEqual(targetFile)) {
			newCachedInstance
		} else {
			jar.getInputStream(entry).streamExtract(targetFile)
		}
	}
	
	/**
	 * Copy the content represented by the given <em>inputStream</em> into the
	 * <em>target file</em>. No checking is performed for equality between input
	 * stream and target file. Data are always written.
	 * 
	 * @return A Result object with information about extraction status
	 */
	private def static streamExtract(InputStream inputStream, File targetFile) {
		if(!targetFile.parentFile.exists) {
			targetFile.parentFile.mkdirs
		}
		val bufferedInput = new BufferedInputStream(inputStream)
		val outputStream = new BufferedOutputStream(
			new FileOutputStream(targetFile)
		)

		val byte[] buffer = newByteArrayOfSize(BUFFER_SIZE)
		var readLength = 0
		while ((readLength = bufferedInput.read(buffer)) != -1) {
			outputStream.write(buffer, 0, readLength)
		}
		bufferedInput.close
		outputStream.close

		return newOkInstance
	}
	

	/**
	 * Search on the file system for a file or folder corresponding to the
	 * given path. If not found, search on the current classpath. If this method
	 * returns an URL, it always represents an existing file.
	 * 
	 * @param path
	 * 			A path
	 * @return
	 * 			An URL for an existing file, or null
	 */
	def static getUrl(String path) {
		val sanitizedPath = path.sanitize

		val file = new File(sanitizedPath)
		if (file.exists)
			return file.toURI.toURL

		// Search in all reachable bundles for the given path resource
		val bundle = FrameworkUtil::getBundle(FilesManager)
		val url =
			if(bundle != null) {
				val bundles = bundle.bundleContext.bundles
				bundles
					// Search only in Orcc plugins
					.filter[symbolicName.contains("orcc")||symbolicName.contains("mdc")]
					// We want an URL to the resource
					.map[getEntry(path)]
					// We keep the first URL not null (we found the resource)
					.findFirst[it != null]
			}
			// Fallback, we are not in a bundle context (maybe unit tests execution?),
			// we use the default ClassLoader method. The problem with this method is
			// that it is not possible to locate resources in other jar archives (even
			// if they are in the classpath)
			else {
				FilesManager.getResource(path)
			}

		if (#["bundle", "bundleresource", "bundleentry"].contains(url?.protocol?.toLowerCase))
			FileLocator.resolve(url)
		else
			url
	}

}
